# Python / native_wj.py / Python 3.11 + Win32 / user-supplied WJ Fly signature in Adobe_10.exe x86
from dataclasses import dataclass
from pathlib import Path
import os,re,struct,time

AOB='F3 0F 7E 40 ?? 66 0F D6 45 ?? 8D ?? ?? ?? ?? ?? 8D ?? ?? ?? ?? ?? ?? ?? F3 0F 7E 4D ?? 8B ?? 8B ?? ?? 8B ?? ?? 85 ?? 0F 84'
ORIGINAL=bytes.fromhex('F3 0F 7E 40')
PATCHED=bytes.fromhex('F3 0F 7E 45')

def signature(pattern):
    parts=pattern.split()
    return re.compile(b'(?=('+b''.join(b'.' if token=='??' else re.escape(bytes.fromhex(token)) for token in parts)+b'))',re.S),len(parts)

MATCHER,WIDTH=signature(AOB)

class PatchError(Exception):
    pass

@dataclass
class Applied:
    pid:int
    identity:object
    address:int
    original:bytes
    owner:object

class NativeWj:
    def __init__(self,finder=None,opener=None):
        self.finder=finder or find_flash
        self.opener=opener or WindowsProcess
        self.applied=None

    def set_enabled(self,enabled,owner):
        previous=self.applied
        if previous and previous.owner!=owner:raise PatchError('O WJ Fly pertence a outra sessao local. Desative na sessao que o ativou.')
        if not enabled:
            if previous is None:return {'enabled':False,'message':'WJ Fly desligado'}
            try:
                process=self.opener(previous.pid)
            except ProcessLookupError:
                self.applied=None
                return {'enabled':False,'message':'Flash encerrado; WJ Fly desligado'}
            with process:
                if process.identity!=previous.identity:
                    self.applied=None
                    return {'enabled':False,'message':'A instancia original do Flash foi encerrada'}
                current=process.read(previous.address,len(PATCHED))
                if current==previous.original:
                    self.applied=None
                    return {'enabled':False,'message':'Bytes originais ja restaurados'}
                if current!=PATCHED:raise PatchError('O codigo mudou depois da ativacao. Nenhum byte foi sobrescrito; feche o Flash para reiniciar.')
                process.write(previous.address+3,previous.original[3:])
                if process.read(previous.address,len(previous.original))!=previous.original:raise PatchError('Nao foi possivel confirmar a restauracao dos bytes.')
            self.applied=None
            return {'enabled':False,'message':'WJ Fly desligado; bytes originais restaurados'}
        if previous:
            try:
                with self.opener(previous.pid) as process:
                    if process.identity==previous.identity and process.read(previous.address,len(PATCHED))==PATCHED:
                        return {'enabled':True,'message':'WJ Fly ja esta ativo'}
            except ProcessLookupError:pass
            raise PatchError('A instancia ou o codigo mudou. Desligue o WJ Fly antes de ativar novamente.')
        pid=self.finder()
        with self.opener(pid) as process:
            matches=set();total=0
            for start,length in process.executable_regions():
                total+=length
                if total>512*1024*1024:raise PatchError('A memoria executavel excede o limite de leitura; nenhuma alteracao foi feita.')
                offset=0;tail=b''
                while offset<length:
                    amount=min(1024*1024,length-offset)
                    data=process.read(start+offset,amount)
                    if len(data)!=amount:raise PatchError('Leitura incompleta da memoria executavel; nenhuma alteracao foi feita.')
                    block=tail+data;base=start+offset-len(tail)
                    matches.update(base+m.start() for m in MATCHER.finditer(block))
                    if len(matches)>1:raise PatchError('AoB ambiguo: mais de uma correspondencia. Nenhuma alteracao foi feita.')
                    tail=block[-(WIDTH-1):];offset+=amount
            if len(matches)!=1:raise PatchError('AoB WJ Fly nao encontrado neste Flash/mapa. Aguarde o mapa carregar e tente novamente.')
            address=matches.pop();original=process.read(address,len(ORIGINAL))
            if original!=ORIGINAL:raise PatchError('Os bytes mudaram durante a busca. Nenhuma alteracao foi feita.')
            # Record before writing so a partially failed write can still be restored.
            record=Applied(pid,process.identity,address,original,owner)
            self.applied=record
            try:
                process.write(address+3,PATCHED[3:])
                if process.read(address,len(PATCHED))!=PATCHED:raise PatchError('Nao foi possivel confirmar os bytes do WJ Fly.')
            except Exception:
                try:
                    current=process.read(address,len(PATCHED))
                    if current==PATCHED or current==original:
                        process.write(address+3,original[3:])
                        self.applied=None
                except Exception:pass
                raise
        return {'enabled':True,'message':'WJ Fly ativo: assinatura unica encontrada'}

    def close(self):
        if self.applied:return self.set_enabled(False,self.applied.owner)
        return {'enabled':False,'message':'WJ Fly desligado'}


def win_api():
    if os.name!='nt':raise PatchError('WJ Fly por AoB requer Windows e Adobe_10.exe de 32 bits.')
    import ctypes as c
    from ctypes import wintypes as w
    k=c.WinDLL('kernel32',use_last_error=True);u=c.WinDLL('user32',use_last_error=True)
    signatures={
        'OpenProcess':([w.DWORD,w.BOOL,w.DWORD],w.HANDLE),
        'CloseHandle':([w.HANDLE],w.BOOL),
        'QueryFullProcessImageNameW':([w.HANDLE,w.DWORD,w.LPWSTR,c.POINTER(w.DWORD)],w.BOOL),
        'ReadProcessMemory':([w.HANDLE,c.c_void_p,c.c_void_p,c.c_size_t,c.POINTER(c.c_size_t)],w.BOOL),
        'WriteProcessMemory':([w.HANDLE,c.c_void_p,c.c_void_p,c.c_size_t,c.POINTER(c.c_size_t)],w.BOOL),
        'VirtualQueryEx':([w.HANDLE,c.c_void_p,c.c_void_p,c.c_size_t],c.c_size_t),
        'VirtualProtectEx':([w.HANDLE,c.c_void_p,c.c_size_t,w.DWORD,c.POINTER(w.DWORD)],w.BOOL),
        'FlushInstructionCache':([w.HANDLE,c.c_void_p,c.c_size_t],w.BOOL),
        'GetProcessTimes':([w.HANDLE,c.POINTER(w.FILETIME),c.POINTER(w.FILETIME),c.POINTER(w.FILETIME),c.POINTER(w.FILETIME)],w.BOOL),
        'GetExitCodeProcess':([w.HANDLE,c.POINTER(w.DWORD)],w.BOOL),
    }
    for name,(args,result) in signatures.items():getattr(k,name).argtypes=args;getattr(k,name).restype=result
    u.GetForegroundWindow.restype=w.HWND
    u.GetWindowThreadProcessId.argtypes=[w.HWND,c.POINTER(w.DWORD)];u.GetWindowThreadProcessId.restype=w.DWORD
    u.IsWindowVisible.argtypes=[w.HWND];u.IsWindowVisible.restype=w.BOOL
    return c,w,k,u


def process_path(k,c,w,handle):
    size=w.DWORD(32768);buf=c.create_unicode_buffer(size.value)
    if not k.QueryFullProcessImageNameW(handle,0,buf,c.byref(size)):raise PatchError('Nao foi possivel identificar o executavel do Flash.')
    return Path(buf.value)


def find_flash():
    c,w,k,u=win_api();found=set();foreground=w.DWORD();u.GetWindowThreadProcessId(u.GetForegroundWindow(),c.byref(foreground))
    callback_type=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)
    def visit(hwnd,param):
        if not u.IsWindowVisible(hwnd):return True
        pid=w.DWORD();u.GetWindowThreadProcessId(hwnd,c.byref(pid));handle=k.OpenProcess(0x1000,False,pid.value)
        if handle:
            try:
                if process_path(k,c,w,handle).name.casefold()=='adobe_10.exe':found.add(pid.value)
            except PatchError:pass
            finally:k.CloseHandle(handle)
        return True
    callback=callback_type(visit);u.EnumWindows.argtypes=[callback_type,w.LPARAM];u.EnumWindows.restype=w.BOOL
    if not u.EnumWindows(callback,0):raise PatchError('Nao foi possivel listar as janelas do Flash.')
    if foreground.value in found:return foreground.value
    if len(found)==1:return found.pop()
    if not found:raise PatchError('Abra o jogo no Adobe_10.exe antes de ativar WJ Fly.')
    raise PatchError('Ha mais de um Adobe_10.exe. Ative o WJ Fly pelo menu da janela desejada.')


class WindowsProcess:
    def __init__(self,pid):
        self.c,self.w,self.k,self.u=win_api();c,w,k=self.c,self.w,self.k
        self.pid=pid;self.handle=k.OpenProcess(0x0400|0x0010|0x0020|0x0008,False,pid)
        if not self.handle:
            if c.get_last_error()==87:raise ProcessLookupError(pid)
            raise PatchError('Sem acesso de leitura/escrita ao Adobe_10.exe. Nenhuma alteracao foi feita.')
        try:
            path=process_path(k,c,w,self.handle)
            if path.name.casefold()!='adobe_10.exe':raise PatchError('O processo selecionado nao e Adobe_10.exe.')
            with path.open('rb') as f:
                head=f.read(64)
                if len(head)!=64 or head[:2]!=b'MZ':raise PatchError('Formato de executavel desconhecido.')
                f.seek(struct.unpack_from('<I',head,60)[0]);pe=f.read(6)
                if pe[:4]!=b'PE\0\0' or pe[4:]!=b'\x4c\x01':raise PatchError('Este AoB foi fornecido para Flash x86; o executavel nao e de 32 bits.')
            created=w.FILETIME();exited=w.FILETIME();kernel=w.FILETIME();user=w.FILETIME()
            if not k.GetProcessTimes(self.handle,c.byref(created),c.byref(exited),c.byref(kernel),c.byref(user)):raise PatchError('Nao foi possivel validar a instancia do Flash.')
            self.identity=(str(path).casefold(),created.dwHighDateTime,created.dwLowDateTime)
        except BaseException:
            k.CloseHandle(self.handle);self.handle=None;raise
    def __enter__(self):return self
    def __exit__(self,*args):
        if self.handle:self.k.CloseHandle(self.handle);self.handle=None
    def read(self,address,length):
        c=self.c;buf=c.create_string_buffer(length);read=c.c_size_t()
        ok=self.k.ReadProcessMemory(self.handle,c.c_void_p(address),buf,length,c.byref(read))
        if not ok or read.value!=length:raise PatchError('Falha de leitura no Adobe_10.exe; o codigo pode ter sido liberado ou o processo encerrado.')
        return buf.raw
    def write(self,address,data):
        c,w,k=self.c,self.w,self.k;old=w.DWORD();written=c.c_size_t();buf=c.create_string_buffer(data,len(data))
        if not k.VirtualProtectEx(self.handle,c.c_void_p(address),len(data),0x40,c.byref(old)):raise PatchError('Nao foi possivel liberar a escrita no bloco selecionado.')
        try:
            if not k.WriteProcessMemory(self.handle,c.c_void_p(address),buf,len(data),c.byref(written)) or written.value!=len(data):raise PatchError('Falha ao escrever os bytes do WJ Fly.')
            if not k.FlushInstructionCache(self.handle,c.c_void_p(address),len(data)):raise PatchError('Falha ao sincronizar o codigo do Flash.')
        finally:
            ignored=w.DWORD()
            if not k.VirtualProtectEx(self.handle,c.c_void_p(address),len(data),old.value,c.byref(ignored)):raise PatchError('Falha ao restaurar a protecao original da pagina de memoria.')
    def executable_regions(self):
        c,w,k=self.c,self.w,self.k
        fields=[('BaseAddress',c.c_void_p),('AllocationBase',c.c_void_p),('AllocationProtect',w.DWORD)]
        if c.sizeof(c.c_void_p)==8:fields.append(('PartitionId',w.WORD))
        fields.extend([('RegionSize',c.c_size_t),('State',w.DWORD),('Protect',w.DWORD),('Type',w.DWORD)])
        class MemoryInfo(c.Structure):_fields_=fields
        address=0
        while address<0x100000000:
            info=MemoryInfo();count=k.VirtualQueryEx(self.handle,c.c_void_p(address),c.byref(info),c.sizeof(info))
            if not count:
                code=w.DWORD()
                if not k.GetExitCodeProcess(self.handle,c.byref(code)) or code.value!=259:raise ProcessLookupError(self.pid)
                if address<0x7fff0000:raise PatchError('Nao foi possivel consultar toda a memoria do Flash.')
                break
            base=info.BaseAddress or 0;length=info.RegionSize
            if length<=0 or base+length<=address:raise PatchError('Mapa de memoria invalido.')
            if info.State==0x1000 and not info.Protect&0x101 and info.Protect&0xf0 in {0x10,0x20,0x40,0x80}:
                yield base,min(length,0x100000000-base)
            address=base+length
