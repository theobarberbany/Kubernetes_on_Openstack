#### Querying Openstack's API

This is mostly included as a troubleshooting tactic, for when `kubectl get events` or the logs ( `/var/logs/containers`) return an error something like 'Error Resource Not Found'

Our internal Openstack has some endpoints turned off, understandably because they are not needed; however if kubernetes decides to request one of them, and gets a 403 it's a bit of a pain to actually work out what's going on.

(One could use curl,  but httpie is a bit more human friendly.)

1. Install httpie :
		`sudo apt install httpie`
        
2. Check it works : 
        
   ```json
    $ http http://172.27.66.32:5000/v2.0
    HTTP/1.1 200 OK
    Content-Length: 338
    Content-Type: application/json
    Date: Fri, 22 Dec 2017 10:03:48 GMT
    Vary: X-Auth-Token
    X-Openstack-Request-Id: req-fb6eb3af-e993-4ca6-b7fb-6ddb48299ed2

    {
        "version": {
            "id": "v2.0",
            "links": [
                {
                    "href": "http://172.27.66.32:5000/v2.0/",
                    "rel": "self"
                },
                {
                    "href": "http://docs.openstack.org/",
                    "rel": "describedby",
                    "type": "text/html"
                }
            ],
            "media-types": [
                {
                    "base": "application/json",
                    "type": "application/vnd.openstack.identity-v2.0+json"
                }
            ],
            "status": "stable",
            "updated": "2014-04-17T00:00:00Z"
        } 
   ```
 
3. Get your authentication token from Keystone: 
    * Take a copy of [token.json](token.json) and edit in your username and password, then request your token. e.g:
      
        ```json
        $ cat token.json

        {"auth":{"passwordCredentials":{"username": "tb15", "password": "*****"}}}

        $ http post http://172.27.66.32:5000/v2.0/tokens < token.json
        
        HTTP/1.1 200 OK
        Content-Length: 368
        Content-Type: application/json
        Date: Fri, 22 Dec 2017 10:12:21 GMT
        Vary: X-Auth-Token
        X-Openstack-Request-Id: req-4fca456a-7902-4855-aebe-91efc2141b13

        {
            "access": {
                "metadata": {
                    "is_admin": 0,
                    "roles": []
                },
                "serviceCatalog": [],
                "token": {
                    "audit_ids": [
                        "letTeRS"
                    ],
                    "expires": "2017-12-22T18:12:21Z",
                    "id": "tokenid",
                    "issued_at": "2017-12-22T10:12:21.669906"
                },
                "user": {
                    "id": "*****",
                    "name": "tb15",
                    "roles": [],
                    "roles_links": [],
                    "username": "tb15"
                }
            }
        }  ```


4. Now query api endpoints :

```json

 $ cat tennant.json
 {
    "auth": {
        "tenantName": "npg-dev",
        "token": {
            "id": "yourtokenhere"
        }
    }
}
```
`http POST http://172.27.66.32:5000/v2.0/tokens < tennant.json`

will return a list of endpoints (also avaliable through Horizon)


  
 
     