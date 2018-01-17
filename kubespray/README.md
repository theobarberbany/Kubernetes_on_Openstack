# Deploying a Kubernetes cluster to Openstack with Kubespray



### Things to know : 

* This is not openshift. It will not work across different tenants, and automatic node scaling is not currently supported (manual is). See here for details about openshift vs stock k8s.

* This assumes that you’ve read the [What is Kubernetes?](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) and [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/) pages in the official docs. 

* All Ansible files are written in the [Jinja](http://jinja.pocoo.org/) templating language. 
* Troubleshooting Terraform is much easier using [this guidance](https://github.com/hashicorp/terraform/pull/12089)
* Run ansible with `-vvvv` for more information debugging
* This assumes you’re using Xenial, with Image name `Ubuntu Xenial` in Openstack. 


### Getting started

* Make sure you have a deployment area with **Python 2.7** with Ansible, Terraform and python netaddr (`pip install netaddr`) installed.

* Having access to the Openstack CLI is also useful.

* Source the openstack login details.

* Have copies of the ssh keys you wish to use handy.

* Open [this readme](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#terraform-variables) 

### Deployment Prep

1. Clone the [Kubespray Repository](https://github.com/kubernetes-incubator/kubespray)
2. Get the [my-terraform-vars.tfvars](/kubespray/my-terraform-vars.tfvars) file and copy it to the root of the cloned directory, and edit to suit your needs.  [Variable explanations](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#terraform-variables)
	* Don’t forget to change the name!
	* Lines 4,5 should remain the same (they define nova, and it’s UUID) 
	* The flavor ID’s can be obtained by running : `openstack flavor list`
	* Update Line 15 with your **public** ssh key
	*  You must have an **odd** number of etcd instances, node defined as `number_of_k8s_masters` or  `number_of_k8s_masters_no_floating_ip` come with an attached etc pod so n >=2
	* You may wish to use the bastion server so nodes do not require floating IP’s See [here](https://github.com/kubernetes-incubator/kubespray/blob/master/docs/ansible.md#bastion-host) and [here](http://blog.scottlowe.org/2015/12/24/running-ansible-through-ssh-bastion-host/)

3. Follow the [terraform](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#terraform) section of  the readme. 
4. You should now have the requested instances provisioned with networks set up correctly. Be sure not to lose or edit the `.tfstate` files that are generated, or else tear down will be difficult.
5. Follow the [Ansible section](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#running-the-ansible-script) stopping before running the deploy script. Do not set networking to `flannel` use `calico` (the default, this allows dynamic LBaaS and Cinder provisioning to work. Don't use `cloud` either as it is only supported on GCP / AWS). Be sure to forward the ports in neutron as outlined below.
   * The ping may will fail,  so long as it's not unreachable it's fine.
   * We must now tell neutron not to drop traffic between nodes. **Follow [this guide](https://github.com/kubernetes-incubator/kubespray/blob/master/docs/openstack.md)** on setting up neutron ports using the neutron CLI. Currently Farm4 has all of the CLI's installed by default for use.
   * `nova list` is sufficient for the first step.
   * If you wish to use GlusterFS, also follow these steps for the gluster nodes.
    
    A shortcut for the port forwarding will be to run the following : 
    ```bash
    $ neutron port-list -c id -c device_id  | grep -E $(nova list   | grep dj3- | awk '{print $2}' | xargs echo | tr ' ' '|') | awk '{print $2}' | xargs -n 1 -I XXX echo neutron port-update XXX --allowed_address_pairs list=true type=dict ip_address=10.233.0.0/18 ip_address=10.233.64.0/18 | bash -eEx
    ```
    and replace `grep dj3` with value of `cluster_name` specified in the tfvars file.


6. At the bottom of `inventory/group_vars/k8s-cluster.yml` add the IP of your computer to the supplementary addresses section (not nessecary - but means less work with SSH required later.)

7. To set up the LBaaS integration edit the `inventory/group_vars/all.yml` at line 77 and below :

   * Set `openstack_blockstorage_version: "v2"` to enable Cinder persistent volume provisioning 
   * Uncomment the entire `LBaaSv2` block, and set 
      1. `openstack_lbaas_floating_network_id: "9f50f282-2a4c-47da-88f8-c77b6655c7db"` (neutron)
      2. `openstack_lbaas_subnet_id: "<Your K8s internal subnet ID>"`
      3. Uncomment `docker_dns_servers_strict: false`
   * Don't try to use Kubeadm, it currently does not support openstack.
   * Don't try to use kpm, it's endpoints no longer exist.


>I would recommend against having it install things like elk, istio and graffana / prometheus for you as there is little documentation on how they are configured, it will probably take less time to install it yourself manually / with Helm later

### Deployment

1. Time to deploy! Follow the guide [from here](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#deploy-kubernetes).
	* Run the command with `--flush-cache` to avoid confusing errors.
	* `ansible-playbook --flush-cache --become -i contrib/terraform/openstack/hosts cluster.yml`
2. Coffee. 
3. SSH into the master node and [set up kubectl](https://github.com/kubernetes-incubator/kubespray/tree/master/contrib/terraform/openstack#set-up-local-kubectl). Do not try adding routes (We will use ssh later).

Running `kubectl version` should now produce input similar to this:
```bash
$ kubecl version 

 Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.4", GitCommit:"9befc2b8928a9426501d3bf62f72849d5cbcd5a3", GitTreeState:"clean", BuildDate:"2017-11-20T05:28:34Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"darwin/amd64"}
 
 Server Version: version.Info{Major:"1", Minor:"8+", GitVersion:"v1.8.4+coreos.0", GitCommit:"4292f9682595afddbb4f8b1483673449c74f9619", GitTreeState:"clean", BuildDate:"2017-11-21T17:22:25Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
 ```
