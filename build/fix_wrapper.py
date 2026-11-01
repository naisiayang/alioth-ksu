import re,sys,py_compile,os
# 运行目录 = kernel 根 (workflow 里 cd kernel 后调用)
p=sys.argv[1] if len(sys.argv)>1 else 'scripts/gcc-wrapper.py'
src=open(p,encoding='utf-8',errors='replace').read()
out=[]
for s in src.split('\n'):
    m=re.match(r'^(\s*)print (.*)$', s)
    if m and not re.match(r'^\s*print\s*\(', s):
        ind,args=m.group(1),m.group(2)
        if args.endswith(','):
            s=f"{ind}print({args[:-1].rstrip()}, end=' ')"
        else:
            s=f"{ind}print({args})"
    out.append(s)
open(p,'w',encoding='utf-8').write('\n'.join(out))
py_compile.compile(p,doraise=True)
print('wrapper->py3 OK')
