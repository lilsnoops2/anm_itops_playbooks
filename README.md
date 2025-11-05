# ANM ITOps Playbooks

This is a collection of playbooks for ANM ITOps automation

- [ANM ITOps Playbooks](#anm-itops-playbooks)
  - [Setup](#setup)
    - [General Setup](#general-setup)
    - [Create Inventory](#create-inventory)
  - [Playbooks](#playbooks)
    - [`update_snmp_acl`](#update_snmp_acl)
    - [`create_accounts`](#create_accounts)
    - [`configure_snmpv3`](#configure_snmpv3)
    - [`remove_snmp`](#remove_snmp)
    - [`http_server`](#http_server)
  - [Prestage](#prestage)

## Setup
### General Setup
**If using from a VASA**, setup is automatic. This repo is cloned to /opt/ansible_local/anm_itops_playbooks. You can force an update by running `bash /opt/anm_ms_ova/sync_anm_itops_playbooks.sh` from the WSL console.

**If not on a VASA,** set up manually:
1. Clone this repo to /opt/ansible_local/anm_itops_playbooks
2. Install the dependencies by running `bash install_requirements.sh`


### Create Inventory
Create one or more inventory files in the inventory folder. See `inventory/default_inventory` for an example.

to create an inventory from MS customer assets use the Splunk dashboard: https://splunk.awscloud.anm.com/en-US/app/splunk_ms_app/ansible_inventory

You can target a host or \[group\] by adding `--limit HOST_OR_GROUP` to the ansible-playbook command


## Playbooks
### `update_snmp_acl`
This playbook updates the SNMP ACL on one or more devices to allow this host's IP address.

Supported OS:
* IOS
* IOS/XE
* NX-OS
* FTD (via FDM)

**Variables**   
- `snmp_string`: The SNMP string to use
- `enable_secret`: Optional: enable secret if device requires it
- `collector_ips`: Optional: List type. Allows for multiple IP addresses of collectors to be passed separated by commas
- `collector_ip`: Optional: Allows for single IP addresses to be passed

**Examples**   
```bash
ansible-playbook playbooks/update_snmp_acl.yml -i inventory.ini -e 'snmp_string=public enable_secret=SOMESECRET' --limit network -u admin -k
```
Add a list of collectors
```bash
ansible-playbook playbooks/update_snmp_acl.yml -i inventory.ini -u admin -k -e 'collector_ips="1.2.3.4,1.2.3.5,1.2.3.6" snmp_string=welcome1'
```
-------------------------------------------------

### `create_accounts`
This playbook creates/ updates ot deletes accounts on one or more devices.

**Variables**   
- `update_password` (optional): If set to "always", the password will be updated, even if the user already exists. If not defined passwords will only be set for new users
- `remove_user` (optional): If set to a username, the user will be removed from the device.
- `add_user` (optional): If set to a username, the user will be added to the device.  
- `add_password` (required for `add_user` and `update_password`): The password to set for the user.
- `enable_secret`: Optional: enable secret if device requires it
  
**Examples**   
Add a user
```bash
ansible-playbook playbooks/create_accounts.yml -e 'add_user=testuser add_password=testpassword enable_secret=SOMESECRET' --limit network -u admin -k
```

Remove a user
```bash
ansible-playbook playbooks/create_accounts.yml -e 'remove_user=testuser enable_secret=SOMESECRET' --limit network -u admin -k
```

Update a user's password
```bash
ansible-playbook playbooks/create_accounts.yml -e 'update_password=always add_user=testuser add_password=testpassword enable_secret=SOMESECRET' --limit network -u admin -k
```
-------------------------------------------------

### `configure_snmpv3`
This playbook creates a readonly group and configures a snmpv3 user

**Variables**   
- `snmpv3_user` (required): Username of the snmpv3 user to be given access
- `auth_password` (required): SHA encrypted password. This is NOT the plaintext password.
- `privacy_password` (required): AES 128 encrypted privacy password. This is NOT the plaintext password.
- `enable_secret`: Optional: enable secret if device requires it


  
**Examples**   
Add a user
```bash
ansible-playbook configure_snmpv3.yml -e 'snmpv3_user=testuser auth_password=Ab39NnC4N3acYABat7AD privacy_password=Ah7Dbh7ABCDARx7nNAjJ enable_secret=SOMESECRET' --limit network -u admin -k

```

-------------------------------------------------

### `remove_snmp`
This playbook removes snmp community strings from the device

Supported OS:
* IOS
* IOS/XE
* NX-OS

**Variables**   
- `snmp_string`: The SNMP string to use
- `enable_secret`: Optional: enable secret if device requires it
  
**Examples**   
Remove snmpv2 community from a device
```bash
ansible-playbook remove_snmp.yml -e 'snmp_string=welcome1' --limit network -u admin -k

```
-------------------------------------------------

### `http_server`
This playbook adds an ACL to an existing http-server enabled switch. Also supports removing the http-server config

Supported OS:
* IOS
* IOS/XE

**Variables**   
- `acl_ips`: Required if remove not set. Type List of string. These are the subnets that will be put into the ACL. Example. acl_ips=["10.16.0.0 0.0.255.255", "10.17.0.0 0.0.255.255"]
- `acl_name`: Required if remove not set. Type string. The name of the ACL that will be applied to the http-server
- `remove`: Required if acl_ips and acl_name are not set. Type bool. Set to "true" to remove the http-server config from the switch. This is mutually exclusive to the acl_ips and acl_name variables. Do not set this and acl_ips/acl_name.
- `enable_secret`: Optional: enable secret if device requires it
  
**Examples**   
Add new ACL to a device with acl_ips defined in inventory.ini
```bash
ansible-playbook http_server.yml -i inventory.ini -e acl_name=test_acl --limit network -u admin -k

```
Add new ACL to a device with acl_ips defined on CLI
```bash
ansible-playbook http_server.yml -i inventory.ini -e 'acl_name=test_acl acl_ips=["10.16.0.0 0.0.255.255", "10.17.0.0 0.0.255.255"]' --limit network -u admin -k

```
Remove http-server config from device
```bash
ansible-playbook http_server.yml -i inventory.ini -e 'remove=true' --limit network -u admin -k
```

## Prestage:
### Pre Reqs:
1. First determine what platform series are available, this list will be used to download the images from Cisco
2. Run the get_platform_series playbook for example:
ansible-playbook playbooks/upgrades/get_platform_series.yml  -e 'target_hosts=switch,router' (Review section for this playbook for further options)

3. The last task will show you a list of device platforms based on the inventory selected, for example:

TASK [Show platform series for selected hosts/groups] ******************************************************************
ok: [ABQ-CORE-01] =>
  msg: |-
    Platform series in use:
    - c2960cx
    - c2960x
    - c3560cx
    - c9000
    - isr4300

4. Go to Cisco and download software for each of these platforms, open up images.yml in Visual Studio (Linux /opt/ansible_local/anm_itops_playbooks/upgrades). If images.yml does not exist, make a copy of images-sample.yml and rename to images.yml
While downloading the software from cisco, make sure to grab the following information and fill out the appropriate device platform in images.yml. For example:
##2960x 2960xr
c2960x_target_image: c2960x-universalk9-mz.152-7.E13.tar
c2960x_md5_hash: 03a1a35666ef516b35e487c31db8e9f9
c2960x_image_size_bytes: 26796032
c2960x_image_code: 15.2(7)E13

5. Save images.yml
6. Once images are downloaded, move the images to the http folder on the desktop (if http folder is missing, refer to Video to set up HTTP server on jumpbox)

NOTE: Make sure that you download .tar files for any IOS device to ensure that archive download-sw can be used:
2960 devices
3560 devices
3750 devices

### Disk Clean Up:
1. Run Disk  Clean up playbook to run through devices and clean up old images to prepare for new image, for example:
ansible-playbook playbooks/upgrades/disk_clean_up.yml  -e 'target_hosts=switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes' (Review section for this playbook for further options)
2. If any devices failed, you may need to manually clean them up

### Image Upload:
1. Run the prestage playbook, for example:
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -e 'target_hosts=switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'http_server=172.22.15.110'
2. If any devices fail, review the failures and fix issues (such as cleaning disk space or fixing http clinet source interface)
3. After fixing devices, you can run on failed devices again by running: 
