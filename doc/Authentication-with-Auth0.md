# Authentication & authorization with Auth0
## Authentication
## Authorization
We will use the roles from Auth0 as the definition of Kubernetes groups. Roles will be created and assigned in Auth0, and K8s will simply reference them to allow or deny access.

### Auth0 setup
By default, the user's roles are not included in the JWT. To add them:
1. Go to auth0 dashboard -> Actions -> Triggers
2. Select the `post-login` trigger
3. Select `Add Action` and `Build from scratch`. Give it a meaningful name (like *Add roles to JWT*) and create it
4. Add the following code:
    ```js
    /**
    * Handler that will be called during the execution of a PostLogin flow.
    *
    * @param {Event} event - Details about the user and the context in which they are logging in.
    * @param {PostLoginAPI} api - Interface whose methods can be used to change the behavior of the login.
    */
    exports.onExecutePostLogin = async (event, api) => { 
      const namespace = '<custom-identifier-like-hostname>'; 
      if (event.authorization) {
        api.idToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
        api.accessToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles); 
      } 
    }
    ```

This will include a section in your JWT payload with the list of roles assigned to the user:
```json
{
    "<custom-identifier-like-hostname>/roles": [
        "my-role",
        "another-role"
    ],
    "iss": ...
}
```

### K8s setup
We also need to tell the cluster which JWT claim to use as the group claim. For that, add the `oidc-groups-claim` configuration in the [`cluster-config.yaml`](../cluster-config.yaml):
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
    ...
    - |
      kind: ClusterConfiguration
      apiServer:
        extraArgs:
          # OIDC related flags
          oidc-issuer-url: "<YOUR-OIDC-ISSUER-URL>"
          oidc-client-id: "<YOUR-OIDC-CLIENT-ID>"
          oidc-groups-claim: "<custom-identifier-like-hostname>/roles"
    ...
```
Now, when the kubernetes API receives a JWT, it will look for the user's groups (or roles from auth0) in that claim.