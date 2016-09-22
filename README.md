README
-------

All the variables in variables.tf are changeable and this can be run by
```
$ terraform plan -var-file=myvars.tfvars # shows execution plan
$ terraform apply -var-file=myvars.tfvars
```

where for eg. myvars.tfvars contain
```
$ cat myvars.tfvars
nat_ami = "ami-foo"
ceph_mon_count= "3"
key_name = "my_key"
```

the aws key must be created before hand and should  be present in your account
the aws credentials can be saved in a file like ~/.aws/credentials or exported in env as described in https://www.terraform.io/docs/providers/aws/index.html

All of this can be undone by running:
```
$ terraform destroy -var-file=myvars.tfvars
```
