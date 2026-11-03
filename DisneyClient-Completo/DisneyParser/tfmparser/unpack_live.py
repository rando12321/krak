# Python / unpack_live.py / Python 3.11 / SWF container extraction without execution
import struct
import zlib

LIMIT = 64 * 1024 * 1024


def expanded(data):
    if len(data)<8 or data[:3] not in (b'FWS',b'CWS'):
        raise ValueError('Unsupported SWF signature')
    length=struct.unpack_from('<I',data,4)[0]
    if not 8<=length<=LIMIT:
        raise ValueError('Invalid SWF length')
    if data[:3]==b'FWS':
        body=data[8:]
    else:
        state=zlib.decompressobj();body=state.decompress(data[8:],length-7)
        if not state.eof or state.unused_data or state.unconsumed_tail:
            raise ValueError('Invalid compressed SWF')
    if len(body)!=length-8:
        raise ValueError('SWF length mismatch')
    return body


def binary_parts(data):
    body=expanded(data)
    if not body:
        raise ValueError('Empty SWF')
    bits=body[0]>>3
    pos=(5+4*bits+7)//8+4
    parts=[]
    while pos+2<=len(body):
        header=struct.unpack_from('<H',body,pos)[0];pos+=2
        code,length=header>>6,header&63
        if length==63:
            if pos+4>len(body):raise ValueError('Truncated SWF tag')
            length=struct.unpack_from('<I',body,pos)[0];pos+=4
        end=pos+length
        if end>len(body):raise ValueError('Truncated SWF content')
        if code==87 and length>=6:parts.append(body[pos+6:end])
        pos=end
        if code==0:break
    return parts


def unpack_game(data):
    parts=binary_parts(data)
    starts=[i for i,p in enumerate(parts) if len(p)>=10 and p[:3]==b'CWS']
    if not starts:
        return data  # Already a game; the symbol extractor validates it next.
    if len(parts)>20:
        raise ValueError('Unsupported split SWF layout')
    solutions=[];attempts=0
    def search(order,state,size,declared):
        nonlocal attempts
        if state.eof:
            if not state.unused_data and not state.unconsumed_tail and size==declared-8:
                candidate=b''.join(parts[i] for i in order)
                if candidate not in solutions:solutions.append(candidate)
            return
        for i,part in enumerate(parts):
            if i in order:continue
            attempts+=1
            if attempts>5000:raise ValueError('Split SWF search limit exceeded')
            trial=state.copy()
            try:chunk=trial.decompress(part,declared-size-7)
            except zlib.error:continue
            total=size+len(chunk)
            if trial.unconsumed_tail or total>declared-8:continue
            search(order+[i],trial,total,declared)
    for i in starts:
        declared=struct.unpack_from('<I',parts[i],4)[0]
        if not 8<declared<=LIMIT:continue
        state=zlib.decompressobj()
        try:head=state.decompress(parts[i][8:],declared-7)
        except zlib.error:continue
        if not state.unconsumed_tail and len(head)<=declared-8:
            search([i],state,len(head),declared)
    if len(solutions)!=1:
        raise ValueError('No unique supported game SWF found in loader')
    expanded(solutions[0])
    return solutions[0]
