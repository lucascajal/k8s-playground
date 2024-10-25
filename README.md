# Kubernetes playground and examples
This repository serves as my personal kubernetes learning journal. It contains examples and tests for testing & playing with kuberentes, using kind. It evolves as new concepts are learned and tested.

The final picture should end up looking similar to the [🚀 ArgoCD Self-Managed Example](https://github.com/imjoseangel/k8s-gitops) repository, which is a core reference for this learning journey, and [it's maintainer](https://github.com/imjoseangel) a k8s mentor of mine. Big kudos to him.

## Usage
### Requirements
Install these CLI tools:
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Helm](https://helm.sh/docs/intro/install/)
- cloudflared - following https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/

You will also need to register in an OIDC provider (we used Auth0) and register an app. Put your app's CLIENT_ID and CLIENT_SECRET in the [oidc-secret.env](oauth2-proxy/oidc-secret.env) file.
### Cluster creation
```bash
make cluster
```
This will:
- Create a kind cluster
- Set up NGINX ingress controller
- Create `dev`, `uat` and `prod` namespaces
- Set up tunnel:
    - Create a Cloudflared tunnel
    - Add DNS records to cloudflare pointing to the tunnel
    - Create cloudflared image deployment
    - Foward all traffic from tunnel to the ingress controller
- Create [OAuth2 Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) deployment pointing to your OIDC app
- Create [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) deployment secured with OIDC


### Cluster deletion
```bash
make destroy
```
## Architecture
### Network topology
![Network topology](doc/network-topology.png)
