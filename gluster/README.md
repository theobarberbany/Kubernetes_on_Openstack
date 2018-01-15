#### Deploying and Mounting GlusterFS (e.g. To run Nextflow)


##### Prerequisites

1. Working Kubernetes cluster, deployed as explained in the kubespray tutorial

##### Terraform 

If you chose not to add a glusterfs node in your initial terraforming then do so now. A brief overview of how to do so can be [found here](https://github.com/kubernetes-incubator/kubespray/blob/master/contrib/network-storage/glusterfs/README.md#using-terraform-and-ansible). 

##### Ansible

1. Assuming you've correctly terraformed your cluster with glusterfs nodes run `ansible -i contrib/terraform/openstack/hosts -m ping all` to ensure the new nodes can be reached. 

2. Now run `ansible-playbook --flush-cache -b --become-user=root -i contrib/terraform/openstack/hosts ./contrib/network-storage/glusterfs/glusterfs.yml` (If you wish to see exactly what ansible is doing, run it with `-vvvv` 

3. Coffee 

4. When the ansible script finishes you should be presented with a new pv in your kubernetes cluster that looks something like this: 

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY STATUS      CLAIM                     STORAGECLASS   REASON    AGE
glusterfs                                  29Gi       RWX            Retain           Available                                                      3d
pvc-60a9ba38-e64e-11e7-803e-fa163edc9f09   10Gi       RWO            Delete           Bound       development/cinderterst   gold                     1h
```

If you ssh into your master node, and cd to the directory `/etc/kubernetes` you will find the following files

``` 
$ cd /etc/kubernetes
$ ls
addons              glusterfs-kubernetes-endpoint.json         kubedns-deploy.yml.j2           node-crb.yml
admin.conf          glusterfs-kubernetes-endpoint-svc.json     kubedns-sa.yml                  node-kubeconfig.yaml
calico-config.yml   glusterfs-kubernetes-pv.yml                kubedns-svc.yml                 openssl.conf
calico-crb.yml      kube-controller-manager-kubeconfig.yaml    kubelet.env                     ssl
calico-cr.yml       kubedns-autoscaler-clusterrolebinding.yml  kube-proxy-kubeconfig.yaml      tokens
calico-node-sa.yml  kubedns-autoscaler-clusterrole.yml         kube-scheduler-kubeconfig.yaml
calico-node.yml     kubedns-autoscaler-sa.yml                  kube-system-ns.yml
cloud_config        kubedns-autoscaler.yml.j2                  manifests
```


The files `glusterfs-kubernetes-endpoint.json` , `glusterfs-kubernetes-endpoint-svc.json` and `glusterfs-kubernetes-pv.yml`

Contain the information that has been added to your kubernetes cluster in order to mount the pv correctly. 

##### Mounting Glusterfs for use with Nextflow

You may also notice that the ansible script makes the directory `/mnt/gluster`. However, by default gluster is in fact not mounted here. (Ansible unmounts it after writing a test file)

When running ansible with `-vvvv` the fstab mount points are returned, but here they are so you don't have to: 

```json
changed: [npg-gfs-node-nf-1] => {
    "changed": true,
    "dump": "0",
    "fstab": "/etc/fstab",
    "fstype": "glusterfs",
    "invocation": {
        "module_args": {
            "boot": "yes",
            "dump": null,
            "fstab": null,
            "fstype": "glusterfs",
            "name": "/mnt/gluster",
            "opts": "defaults,_netdev",
            "passno": null,
            "path": "/mnt/gluster",
            "src": "10.0.0.15:/gluster",
            "state": "mounted"
        }
    },
    "name": "/mnt/gluster",
    "opts": "defaults,_netdev",
    "passno": "0",
    "src": "10.0.0.15:/gluster"
}
```

My server's ip's are `10.0.0.15` and `10.0.0.14` so I can now mount glusterfs using the above information using the following command, as ansible will have already installed the glusterfs client. (SSH'd into a node)

`sudo mount -t glusterfs 10.0.0.15:/gluster /mnt/gluster`

and so on.

now running `df -h` reuturns something like this: 

```
$ df -h

udev                2.0G     0  2.0G   0% /dev
tmpfs               396M   41M  355M  11% /run
/dev/vda1            12G  6.1G  5.5G  53% /
tmpfs               2.0G     0  2.0G   0% /dev/shm
tmpfs               5.0M     0  5.0M   0% /run/lock
tmpfs               2.0G     0  2.0G   0% /sys/fs/cgroup
tmpfs               396M     0  396M   0% /run/user/1000
10.0.0.15:/gluster   30G  5.5G   25G  19% /mnt/gluster
```

Repeat the above steps on all nodes in your cluster if you wish to use nextflow, then ssh back into your **master** and run nextflow from the directory `/mnt/gluster`.

(SSH into master as it has kubectl set up by default, and nextflow requires kubectl to execute kubernetes commands.)

For a more robust method of mounting, see here: https://www.jamescoyle.net/how-to/439-mount-a-glusterfs-volume

Currently (December 2017) Nextflow does not support using the PV system that is provided by kubernetes 

Issues [#446](https://github.com/nextflow-io/nextflow/issues/446) and [#468](https://github.com/nextflow-io/nextflow/issues/468) address this. 