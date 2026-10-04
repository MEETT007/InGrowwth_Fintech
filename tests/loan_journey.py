"""Local sandbox integration test. Creates a test borrower and completes one loan."""
import json, urllib.request, urllib.error, http.cookiejar, uuid, os, socket
BASE=os.getenv('TEST_API_URL','http://127.0.0.1:8080')+'/api/'
checks=0
class Client:
 def __init__(self):
  self.jar=http.cookiejar.CookieJar();self.http=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar));self.csrf=self.call('auth/session')['csrf']
 def call(self,path,body=None,expected=200,raw=None,ctype=None,csrf=True):
  global checks
  data=raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
  headers={} if data is None else {'Content-Type':ctype or 'application/json'}
  if csrf and data is not None:headers['X-XSRF-TOKEN']=self.csrf
  req=urllib.request.Request(BASE+path,data=data,headers=headers)
  try:
   with self.http.open(req,timeout=10) as r:status=r.status;content=r.read()
  except urllib.error.HTTPError as e:status=e.code;content=e.read()
  assert status==expected,(path,status,content.decode(errors='replace')[:500])
  checks+=1
  try:return json.loads(content)
  except ValueError:return content
 def login(self,email):
  self.call('auth/login',{'email':email,'password':os.getenv('DEMO_PASSWORD','DemoHome!2026')});self.csrf=self.call('auth/session')['csrf']
b=Client();o=Client();other=Client();o.login('officer@demo.ingrowwth');other.login('second@demo.ingrowwth')
email='journey-'+uuid.uuid4().hex[:12]+'@example.test'
b.call('auth/register',{'email':email,'name':'Journey Test','password':'TestingHome!2026'})
b.call('auth/login',{'email':email,'password':'TestingHome!2026'});b.csrf=b.call('auth/session')['csrf']
app=dict(applicantName='Journey Test',email=email,city='Ahmedabad',employment='SALARIED',purpose='CONSTRUCTION',propertyAddress='Test property, Ahmedabad',coApplicant='',income=125000,coIncome=0,obligations=10000,propertyValue=6500000,requestedAmount=4500000,annualRate=8.5,tenureMonths=240)
b.call('loans',app,expected=403,csrf=False)
d=b.call('loans',app);id=d['loan']['id'];path='loans/'+id
other.call(path,expected=404)
assert all(x['id']!=id for x in other.call('loans'));checks+=1
def action(client,name,expected=200,**kwargs):
 global d
 d=b.call(path)
 result=client.call(path+'/actions',dict(action=name,revision=d['loan']['revision'],**kwargs),expected=expected)
 if expected==200:d=result
 return result
action(b,'ADVANCE',403)
action(b,'SUBMIT');action(o,'SANCTION',400,note='Trying to skip required reviews')
action(o,'ADVANCE');action(o,'ADVANCE',400)
action(o,'QUERY',note='Please confirm the property address matches the documents.')
q=d['queries'][0]['id'];action(o,'ADVANCE',400)
action(b,'RESPOND',targetId=q,note='The property address matches the attached documents.')
action(o,'RESOLVE_QUERY',targetId=q)
for kind in ['Identity proof','Income proof','Bank statements','Property documents']:
 d=b.call(path);boundary='Boundary'+uuid.uuid4().hex
 parts=[]
 for k,v in [('kind',kind),('revision',str(d['loan']['revision']))]:parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
 parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="test.pdf"\r\nContent-Type: application/pdf\r\n\r\n'.encode()+b'%PDF-1.4\n% Test document\n%%EOF\n'+f'\r\n--{boundary}--\r\n'.encode())
 d=b.call(path+'/documents',raw=b''.join(parts),ctype='multipart/form-data; boundary='+boundary)
 doc=d['documents'][-1]['id']
 other.call(path+'/documents/'+doc,expected=404)
 action(o,'VERIFY_DOCUMENT',targetId=doc)
action(o,'ADVANCE');action(o,'ADVANCE',400)
action(o,'REVIEW',targetId='CREDIT',note='Income and obligations reviewed for this sandbox test.')
action(o,'ADVANCE');action(o,'SANCTION',400,note='Reviews still incomplete')
action(o,'REVIEW',targetId='LEGAL',note='Property title review recorded for the sandbox.')
action(o,'REVIEW',targetId='VALUATION',note='Property valuation reviewed for the sandbox.')
action(o,'SANCTION',note='Sandbox sanction following required manual checks.')
action(o,'DISBURSE',400,amount=1000000,note='TEST-TRANCHE-BEFORE-ACCEPT')
action(b,'ACCEPT_SANCTION')
stale=d['loan']['revision'];action(o,'DISBURSE',amount=1500000,note='TEST-TRANCHE-ONE')
assert d['loan']['stage']=='DISBURSEMENT';checks+=1
interest=round(d['loan']['outstanding']*d['loan']['annualRate']/1200,2)
pre=b.call(path+'/payments',dict(amount=interest,kind='PRE_EMI',mode='TENURE',idempotencyKey=uuid.uuid4().hex))
d=o.call(path+'/payments/'+pre['id']+'/confirm',dict(reference='TEST-PRE-EMI'))
assert d['loan']['outstanding']==1500000 and d['loan']['paidInterest']==interest;checks+=1
o.call(path+'/actions',{'action':'DISBURSE','revision':stale,'amount':3000000,'note':'STALE-UPDATE'},expected=409)
action(o,'DISBURSE',amount=3000000,note='TEST-TRANCHE-TWO')
assert d['loan']['stage']=='ACTIVE';checks+=1
amount=d['loan']['emi'];before=d['loan']['outstanding'];key=uuid.uuid4().hex
p=b.call(path+'/payments',dict(amount=amount,kind='EMI',mode='TENURE',idempotencyKey=key))
p2=b.call(path+'/payments',dict(amount=amount,kind='EMI',mode='TENURE',idempotencyKey=key))
assert p['id']==p2['id'];checks+=1
b.call(path+'/payments',dict(amount=amount,kind='EMI',mode='TENURE',idempotencyKey=uuid.uuid4().hex),expected=400)
b.call(path+'/payments',dict(amount=amount+1,kind='EMI',mode='TENURE',idempotencyKey=key),expected=409)
b.call(path+'/payments/'+p['id']+'/confirm',dict(reference='BORROWER-FORBIDDEN'),expected=403)
d=o.call(path+'/payments/'+p['id']+'/confirm',dict(reference='TEST-EMI-RECEIPT'))
assert d['loan']['outstanding']<before;checks+=1
balance=d['loan']['outstanding'];d=o.call(path+'/payments/'+p['id']+'/confirm',dict(reference='TEST-EMI-REPEAT'))
assert d['loan']['outstanding']==balance;checks+=1
p=b.call(path+'/payments',dict(amount=100000,kind='PREPAYMENT',mode='TENURE',idempotencyKey=uuid.uuid4().hex))
d=o.call(path+'/payments/'+p['id']+'/confirm',dict(reference='TEST-PREPAYMENT'))
assert d['loan']['outstanding']==round(balance-100000,2);checks+=1
assert d['loan']['remainingMonths']<239;checks+=1
cancel=b.call(path+'/payments',dict(amount=5000,kind='PREPAYMENT',mode='TENURE',idempotencyKey=uuid.uuid4().hex))
d=b.call(path+'/payments/'+cancel['id']+'/cancel',{})
o.call(path+'/payments/'+cancel['id']+'/confirm',dict(reference='CANCELLED-RECEIPT'),expected=400)
assert d['loan']['outstanding']==round(balance-100000,2);checks+=1
p=b.call(path+'/payments',dict(amount=d['loan']['outstanding'],kind='PREPAYMENT',mode='TENURE',idempotencyKey=uuid.uuid4().hex))
d=o.call(path+'/payments/'+p['id']+'/confirm',dict(reference='TEST-FULL-CLOSURE'))
assert d['loan']['stage']=='CLOSED' and d['loan']['outstanding']==0;checks+=1
for task in ['CERTIFICATE','ORIGINALS','SECURITY']:action(o,'CLOSURE_CHECK',targetId=task)
assert d['loan']['closureCertificate'] and d['loan']['originalsReturned'] and d['loan']['securityReleased'];checks+=1
scenario=dict(principal=4500000,annualRate=8.5,months=240,extraMonthly=5000,annualExtra=25000,oneTime=100000,oneTimeMonth=12,prepayMode='TENURE',resetMonth=0,resetRate=9.5,resetMode='EMI',fees=0,startDate='2026-11-05')
c=b.call('planner',scenario);assert c['interestSaved']>0 and c['monthsSaved']>0;checks+=1
b.call('planner',dict(scenario,principal=-1),expected=400)
# Verify delivery and recipient isolation for a committed change.
streams=[]
for client in [b,o,other]:
 req=urllib.request.Request(BASE+'events',headers={'Accept':'text/event-stream'})
 stream=client.http.open(req,timeout=2);streams.append(stream)
 while stream.readline().strip():pass
 checks+=1
action(o,'CLOSURE_CHECK',targetId='CERTIFICATE')
for stream in streams[:2]:
 line=stream.readline().decode()
 assert line.startswith('event:case-update'),line
 data=stream.readline().decode()
 assert json.loads(data.removeprefix('data:'))['loanId']==id
 checks+=1
try:
 line=streams[2].readline()
 raise AssertionError('Another borrower received an update: '+repr(line))
except (TimeoutError,socket.timeout):checks+=1
finally:
 for stream in streams:stream.close()
print(f'{checks} integration checks passed. Test loan: {id}')
