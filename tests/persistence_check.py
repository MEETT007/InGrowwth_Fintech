"""Run record, restart Java, then check to verify actual database/file persistence."""
import urllib.request, http.cookiejar, json, pathlib, sys, hashlib, os
jar=http.cookiejar.CookieJar();http=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
base='http://127.0.0.1:8080/api/'
def request(path,body=None,csrf=''):
 data=None if body is None else json.dumps(body).encode()
 req=urllib.request.Request(base+path,data=data,headers={'Content-Type':'application/json','X-XSRF-TOKEN':csrf})
 with http.open(req,timeout=10) as r:
  content=r.read()
  return json.loads(content) if r.headers.get_content_type()=='application/json' else content
csrf=request('auth/session')['csrf']
request('auth/login',{'email':'officer@demo.ingrowwth','password':os.getenv('DEMO_PASSWORD','DemoHome!2026')},csrf)
loans=request('loans')
loan=next(l for l in loans if l['stage']=='CLOSED' and l['applicantName']=='Journey Test')
d=request('loans/'+loan['id'])
doc=d['documents'][0]
content=request('loans/'+loan['id']+'/documents/'+doc['id'])
snapshot={'loan':d['loan'],'counts':{k:len(d[k]) for k in ['events','queries','payments','documents']},'fileHash':hashlib.sha256(content).hexdigest(),'totalLoans':len(loans)}
file=pathlib.Path(__file__).resolve().parents[1]/'.local'/'persistence.json'
if sys.argv[1]=='record':
 file.parent.mkdir(exist_ok=True);file.write_text(json.dumps(snapshot));print('Persistence snapshot recorded.')
else:
 assert snapshot==json.loads(file.read_text()),'Persisted records or private document changed after restart.'
 print('Persistence passed: loan balance, closure flags, history, payments, documents and private file survived restart.')
