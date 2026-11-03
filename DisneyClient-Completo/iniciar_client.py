# Python / iniciar_client.py / Python 3.11+ / Windows DisneyClient launcher
from pathlib import Path
import argparse
from collections import deque
import hashlib
import datetime
import shutil
import json
import os
import socket
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.request
import venv
import webbrowser

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR
CLIENT = ROOT / 'DisneyClient'
PARSER = ROOT / 'DisneyParser'
RUNTIME = ROOT / '.client-runtime'
LOGS = ROOT / 'logs-client'


def is_project(path):
    return all((path/name).is_file() for name in
               ('DisneyClient/server.py','DisneyClient/requirements.txt','DisneyParser/main.py'))


def find_projects(seeds, max_depth=3, max_dirs=500):
    queue=deque((Path(seed),0) for seed in seeds)
    visited=set();found=[]
    skip={'atualizacao','.client-runtime','.git','.venv','venv','node_modules','__pycache__'}
    while queue and len(visited)<max_dirs:
        folder,depth=queue.popleft()
        try:
            folder=folder.resolve()
            if folder in visited:continue
            visited.add(folder)
            if is_project(folder):
                found.append(folder)
                continue
            if depth>=max_depth:continue
            for child in sorted(folder.iterdir()):
                if child.is_dir() and not child.is_symlink() and child.name not in skip and not child.name.startswith('backup-'):
                    queue.append((child,depth+1))
        except OSError:
            continue
    return found


def configure_project(explicit=None):
    global ROOT,CLIENT,PARSER,RUNTIME,LOGS
    selected=None
    if explicit:
        candidate=Path(explicit).expanduser().resolve()
        if is_project(candidate):selected=candidate
    else:
        # Prefer this installation and its parents; never open a folder dialog.
        for candidate in [SCRIPT_DIR]+list(SCRIPT_DIR.parents)[:3]:
            if is_project(candidate):
                selected=candidate
                break
        saved=SCRIPT_DIR/'.client-project.json'
        if selected is None and saved.is_file():
            try:
                previous=json.loads(saved.read_text(encoding='utf-8')).get('project')
                if isinstance(previous,str) and is_project(Path(previous)):selected=Path(previous)
            except (OSError,ValueError,AttributeError):pass
        if selected is None:
            nearby=find_projects([SCRIPT_DIR],max_depth=2)
            if len(nearby)==1:selected=nearby[0]
    if selected is None or not is_project(selected):
        raise RuntimeError('Coloque INICIAR_CLIENT.bat e iniciar_client.py na pasta DisneyClient-Completo, ao lado das pastas DisneyClient e DisneyParser. Nao execute de dentro do ZIP.')
    ROOT=selected.resolve();CLIENT=ROOT/'DisneyClient';PARSER=ROOT/'DisneyParser'
    RUNTIME=ROOT/'.client-runtime';LOGS=ROOT/'logs-client'


def runtime_python():
    return RUNTIME / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')


def apply_update():
    source=SCRIPT_DIR/'atualizacao'
    if not source.is_dir():return
    files=sorted(p for p in source.rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    digest=hashlib.sha256()
    for item in files:
        digest.update(str(item.relative_to(source)).replace('\\','/').encode())
        digest.update(item.read_bytes())
    value=digest.hexdigest()
    marker=RUNTIME/'update.sha256'
    if marker.is_file() and marker.read_text().strip()==value:return
    backup=ROOT/('backup-iniciador-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
    print('Aplicando atualizacao do fluxo automatico, com backup...',flush=True)
    for item in files:
        relative=item.relative_to(source)
        dest=ROOT/relative
        if dest.exists():
            saved=backup/relative;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,saved)
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(item,dest)
    RUNTIME.mkdir(exist_ok=True)
    marker.write_text(value)


def bootstrap():
    if sys.version_info < (3, 11):
        raise RuntimeError('Instale Python 3.11 ou superior e abra INICIAR_CLIENT.bat novamente.')
    for path in (CLIENT/'server.py', CLIENT/'requirements.txt', PARSER/'main.py'):
        if not path.is_file():
            raise RuntimeError('Extraia estes arquivos na pasta que contem DisneyClient e DisneyParser.')
    apply_update()
    if not runtime_python().is_file():
        print('Preparando Python do client (somente na primeira vez)...', flush=True)
        venv.EnvBuilder(with_pip=True).create(RUNTIME)
    requirements = CLIENT/'requirements.txt'
    digest = hashlib.sha256(requirements.read_bytes()).hexdigest()
    stamp = RUNTIME/'requirements.sha256'
    if not stamp.is_file() or stamp.read_text().strip() != digest:
        print('Instalando dependencias. A primeira abertura precisa de internet...', flush=True)
        subprocess.run([str(runtime_python()), '-m', 'pip', 'install', '-r', str(requirements)], check=True)
        stamp.write_text(digest)
    return subprocess.call([str(runtime_python()), str(Path(__file__).resolve()), '--ready', '--project', str(ROOT)])


def listening(port):
    with socket.socket() as connection:
        connection.settimeout(0.3)
        return connection.connect_ex(('127.0.0.1', port)) == 0


def http_ok(url, token=None):
    headers = {'Authorization': 'Bearer '+token} if token else {}
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=2) as response:
            return response.status == 200
    except (OSError, urllib.error.HTTPError):
        return False


def http_data(url):
    try:
        with urllib.request.urlopen(url,timeout=2) as response:
            data=json.loads(response.read(8192))
            return data if isinstance(data,dict) else {}
    except (OSError,ValueError,urllib.error.HTTPError):
        return {}


def wait_ready(child, url, label, token=None, timeout=150):
    deadline = time.monotonic()+timeout
    while time.monotonic() < deadline:
        if child.poll() is not None:
            raise RuntimeError(label+' encerrou. Consulte a pasta logs-client.')
        if http_ok(url, token):
            return
        time.sleep(0.4)
    raise RuntimeError(label+' nao ficou pronto. Verifique MySQL/XAMPP, .env e logs-client.')


def run():
    from dotenv import load_dotenv
    settings=CLIENT/'.env'
    if not settings.is_file():
        example=CLIENT/'.env.example'
        if not example.is_file():
            raise RuntimeError('Falta DisneyClient/.env. Configure o banco conforme LEIA-ME-COMPLETO.txt.')
        shutil.copyfile(example,settings)
        print('Configuracao local criada em DisneyClient/.env; ajuste se seu MySQL usar senha ou porta diferente.',flush=True)
    load_dotenv(settings)
    env = os.environ.copy()
    port = int(env.get('SERVER_PORT', env.get('PORT', '8080')))
    parser_port = int(env.get('CLIENT_PARSER_PORT', '8090'))
    if port == parser_port or any(not 1 <= p <= 65535 for p in (port, parser_port)):
        raise RuntimeError('SERVER_PORT e CLIENT_PARSER_PORT devem ser portas diferentes entre 1 e 65535.')
    url = 'http://127.0.0.1:'+str(port)
    public_url = 'http://207.180.3.127:'+str(port)
    parser_url = 'http://127.0.0.1:'+str(parser_port)
    token_file=PARSER/'tokens.json'
    if not token_file.is_file():
        local_token=env.get('TFM_PARSER_API_TOKEN') or secrets.token_hex(32)
        token_file.write_text(json.dumps([local_token]),encoding='utf-8')
    tokens = json.loads(token_file.read_text(encoding='utf-8-sig'))
    if not isinstance(tokens, list) or not tokens or any(not isinstance(t,str) or not t.strip() for t in tokens):
        raise RuntimeError('DisneyParser/tokens.json precisa conter uma lista com pelo menos um token valido.')
    token = env.get('TFM_PARSER_API_TOKEN') or tokens[0]
    if token not in tokens:
        raise RuntimeError('TFM_PARSER_API_TOKEN nao esta na lista DisneyParser/tokens.json.')
    parser_ready = http_ok(parser_url+'/api/tfm_keys', token)
    client_ready = http_ok(url+'/health')
    build_file=CLIENT/'BUILD-ID.txt'
    if client_ready and build_file.is_file() and http_data(url+'/health').get('build_id')!=build_file.read_text().strip():
        raise RuntimeError('Outra versao do client ainda esta aberta. Feche a janela INICIAR_CLIENT anterior e o Adobe Flash Player e tente novamente.')
    if listening(port) and not client_ready:
        raise RuntimeError('A porta do backend esta ocupada ou o banco esta indisponivel. Consulte SERVER_PORT e MySQL/XAMPP.')
    if listening(parser_port) and not parser_ready:
        raise RuntimeError('A porta do parser esta ocupada ou ele esta com erro. Consulte CLIENT_PARSER_PORT e o log do parser.')
    # A running backend may use another parser configuration; never claim to reconfigure it.
    if client_ready and not parser_ready:
        raise RuntimeError('O backend ja esta aberto sem o parser local pronto. Feche a instancia anterior e inicie por este arquivo.')
    env.update(SERVER_HOST='0.0.0.0', SERVER_PORT=str(port),
               TFM_PARSER_ENDPOINT=parser_url, TFM_PARSER_API_TOKEN=token,
               PYTHONUNBUFFERED='1')
    LOGS.mkdir(exist_ok=True)
    children=[]
    handles=[]
    def spawn(folder, script, name, child_env):
        log=open(LOGS/(name+'.log'),'ab',buffering=0)
        handles.append(log)
        child=subprocess.Popen([sys.executable,script],cwd=folder,env=child_env,
                                 stdout=log,stderr=subprocess.STDOUT)
        children.append(child)
        return child
    try:
        if not parser_ready:
            print('Iniciando parser...', flush=True)
            child=spawn(PARSER,'main.py','parser',dict(env,PORT=str(parser_port)))
            wait_ready(child,parser_url+'/api/tfm_keys','Parser',token)
        if not client_ready:
            print('Iniciando backend...', flush=True)
            child=spawn(CLIENT,'server.py','backend',env)
            wait_ready(child,url+'/health','Backend')
        print('Abrindo '+public_url,flush=True)
        if not webbrowser.open(public_url):
            print('Abra este endereco no seu navegador ou runtime Flash compativel: '+public_url)
        if children:
            print('Client iniciado. Deixe esta janela aberta. Ctrl+C encerra os processos iniciados aqui.',flush=True)
            while True:
                for child in children:
                    if child.poll() is not None:
                        raise RuntimeError('Um componente encerrou. Consulte a pasta logs-client.')
                time.sleep(0.5)
        return 0
    except KeyboardInterrupt:
        print('\nEncerrando client...')
        return 0
    finally:
        for child in children:
            if child.poll() is None:
                child.terminate()
        for child in children:
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
        for handle in handles:
            handle.close()


if __name__ == '__main__':
    try:
        options=argparse.ArgumentParser()
        options.add_argument('--ready',action='store_true')
        options.add_argument('--project')
        args=options.parse_args()
        configure_project(args.project)
        sys.exit(run() if args.ready else bootstrap())
    except KeyboardInterrupt:
        print('\nEncerrado.')
        sys.exit(0)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        # No credential values or exception bodies from network/database requests.
        if isinstance(error, RuntimeError):
            print('\nERRO: '+str(error))
        else:
            print('\nERRO: '+type(error).__name__+'. Verifique a configuracao e a pasta logs-client.')
        sys.exit(1)
