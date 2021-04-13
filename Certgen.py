import ipfsApi
import json

#Certconv = json.dumps(cert)

api = ipfsApi.Client('127.0.0.1', 5001)
res = api.add('cert.json')
farmerCert = api.cat(res['Hash'])


farmerCertJson = json.loads(farmerCert)
print(farmerCertJson['requesterPubAddress'])
print(farmerCertJson['productID'])

