# ANM ITOps Playbooks

This is a collection of playbooks for ANM ITOps automation

- [ANM ITOps Playbooks](#anm-itops-playbooks)
  - [Setup](#setup)
    - [General Setup](#general-setup)
    - [Create Inventory](#create-inventory)
    - [Splunk Inventory](#splunk-inventory)
  - [Playbooks](#playbooks)
    - [`update_snmp_acl`](#update_snmp_acl)
    - [`create_accounts`](#create_accounts)
    - [`configure_snmpv3`](#configure_snmpv3)
    - [`remove_snmp`](#remove_snmp)
    - [`http_server`](#http_server)
    - [`get_platform_series`](#get_platform_series)
    - [`disk_clean_up`](#disk_clean_up)
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

### Splunk Inventory
#### Inventory Info
Splunk Inventory will use an excel sheet downloaded from Splunk to dynamically create the inventory used by playbooks. This plug in will automatically create groups for devices based on whether it is a switch, router, etc. As well as a group based on the platform series. A devices platform series is grouped because many different types of devices are technically the same series and therefore use the same software image. For example, Catalyst 9300, 9500, 9407, 9406 are all part of the platform series c9000, meaning all of these devices will use the same software image (cat9k). While the current inventory is comprehensive, grouping of platform series is still in work in progress as we come across different device types.

The Splunk inventory script is automatically used when you run a playbook from the /opt/ansible_local/anm_itops_playbooks folder (this is where ansible.cfg is located and used). However, you can directly pass in the inventory by itself if needed using:
```
-i '/opt/ansible_local/anm_itops_playbooks/inventory/excel_python.py'
```

To view the inventory directly, you can run:
```
./inventory/excel_inventory.py
```

Most playbooks that use the -e option of "target_hosts" or prompt for target hosts can use any of the groups or hosts to run the playbook. You can use a single group, multiple groups, single host, multiple hosts, combination groups/hosts. You split the differing variables with a comma (,) no space, for example:
Single Group: switches
Multiple Group: switches,routers,firewalls
Single Host: switch1
Multiple Host: switch1,switch2,router2
Combination: switches,router1

When using a group, all devices associated to that group will be targeted. 

Playbooks that utilize the target hosts variable are dynamic in nature meaning you can pick and choose groups/hosts allowing you to be granular on what devices to run on.

Since the script uses the inventory directly from Splunk, it is best to obtain the names of the hosts that you wish to run a playbook on directly from SNOW CMDB, since the hostnames in SNOW should match those in Splunk.

By default, ansible-playbook will use all available inventory files available in inventory/ folder.

#### Download Excel File
1. Open the Splunk inventory link and log in (can be done on the VASA/PASA):

    [Splunk](https://splunk.awscloud.anm.com/en-US/app/splunk_ms_app/lm_device_explorer?form.COMPANY=*&form.FIELDS=displayName&form.FIELDS=sn.sys_class_name&form.FIELDS=auto.anm_model&form.FIELDS=auto.anm_os&form.FIELDS=auto.anm.firmware&form.FIELDS=sn.u_anm_support_level&form.CLASS=cmdb_ci_ip_router&form.CLASS=cmdb_ci_ip_switch&form.CLASS=cmdb_ci_ip_firewall&form.CLASS=u_cmdb_ci_fmc&form.CLASS=u_cmdb_ci_wireless_controller&form.CLASS=u_cmdb_ci_ise_acs&form.SEARCH=*%20sn.u_anm_support_level!%3D%22Retired%22%20sn.u_anm_support_level!%3D%22Not%20Supported%22%20sn.u_anm_support_level!%3D%22Offboarded%22)


2. Set **Company** and remove `All` from the company field.

3. Verify the following fields are present:

- `displayName`  
- `sn.sys_class_name`  
- `auto.network.address`  
- `auto.anm_os`  
- `auto.anm_model`  
- `auto.anm_firmware`  
- `sn.u_anm_support_level`  

4. Verify the following classes are present:

- `cmdb_ci_ip_router`  
- `cmdb_ci_ip_switch`  
- `cmdb_ci_ip_firewall`
- `u_cmdb_ci_fmc`
- `u_cmdb_ci_wireless_controller`
- `u_cmdb_ci_ise_acs`

5. Verify search/filter is present:

```
sn.u_anm_support_level!="Retired" sn.u_anm_support_level!="Not Supported" sn.u_anm_support_level!="Offboarded"
```

6. **Download XLSX**:

- Click on "Download Device List"
- This will download a file named "lm_devices.xlsx"
- rename file to "inventory.xlsx"

7. Move the file to the following Folder in Linux WSL:

```
/opt/ansible_local/anm_itops_playbooks/inventory
```
8. Test by running the follwoing from a WSL cmd
```
cd /opt/ansible_local/anm_itops_playbooks
./inventory/excel_inventory.py
```
This should return an output similar to the following:
```
{
    "_meta": {
        "hostvars": {
            "switch1": {
                "ansible_host": "1.1.1.1",
                "platform_series": "c9000",
                "pid": "c9300-48p",
                "ansible_network_os": "ios",
                "ansible_connection": "network_cli",
                "platform_os": "ios_xe",
                "auto.anm.firmware": "17.6.4"
            },
            "switch2": {
                "ansible_host": "2.2.2.2",
                "platform_series": "c9000",
                "pid": "c9410r",
                "ansible_network_os": "ios",
                "ansible_connection": "network_cli",
                "platform_os": "ios_xe",
                "auto.anm.firmware": "17.12.4"
            "firewall1": {
                "ansible_host": "3.3.3.3",
                "platform_series": "asa5506",
                "pid": "asa5506",
                "ansible_network_os": "asa",
                "ansible_connection": "network_cli",
                "platform_os": "asa",
                "auto.anm.firmware": "9.8.2"
            }
        }
    },
    "switch": {
        "hosts": [
            "METCTSW-STK6A",
            "switch1",
            "swiutch2"
        ]
    },
    "c9000": {
        "hosts": [
            "switch1",
            "switch2",
        ]
    },
    "firewall": {
        "hosts": [
            "firewall1",
        ]
    "asa5506": {
        "hosts": [
            "firewall1"
        ]
    },
    }
}
```

## Playbooks
<details>
<summary>update_snmp_acl</summary>
  
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
</details>
-------------------------------------------------

<details>
<summary>create_accounts</summary>
  
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
</details>
-------------------------------------------------
<details>
<summary>configure_snmpv3</summary>
  
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
</details>
-------------------------------------------------
<details>
<summary>remove_snmp</summary>
  
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
</details>
-------------------------------------------------
<details>
<summary>http_server</summary>

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
</details>
-------------------------------------------------
<details>
<summary>get_platform_series</summary>
  
### `get_platform_series`
This playbook shows the platform series from inventory, i.e c9000. It is used as a pre step for upgardes and helps to minimize the amount of discovery needed to prepare for downloading images.

Supported OS:
* All

**Variables**
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
- `target_hosts` (required): The  groups/hosts that you'd like to know the platform series for. Example: -e 'target_hosts=switch,router' will return the platform series for all devices belongiong to groups switch or router.

**Examples**   
Shows platform series for all hosts/groups
```bash
ansible-playbook playbooks/gio-temp/upgrades/get_platform_series.yml -e "target_hosts=all"
```

Output:
```bash
TASK [Show platform for selected hosts/groups] ********************************************************************************************************************************************************************
ok: [switch1] =>
  hostvars[inventory_hostname]["platform_series"]: c9000
ok: [switch2] =>
  hostvars[inventory_hostname]["platform_series"]: c2960x
ok: [switch3] =>
  hostvars[inventory_hostname]["platform_series"]: c2960x
ok: [switch4] =>
  hostvars[inventory_hostname]["platform_series"]: c9000
ok: [firewall1] =>
  hostvars[inventory_hostname]["platform_series"]: asa5506

TASK [Show platform series for selected hosts/groups] *************************************************************************************************************************************************************
ok: [sw1] =>
  msg: |-
    Platform series in use:
    - asa5506
    - c2960x
    - c9000
```

The Task named "Show platform for selected hosts/groups" will show the platform series for each device
The task named "Show platform series for selected hosts/groups" will show the comboind platform series for the hosts/groups.

In this example, you would then go to Cisco software download and download the image for 2960x, c9000, and asa5506. Downloading those 3 will cover all devices' software requirements.
</details>
-------------------------------------------------
<details>
<summary>disk_clean_up</summary>
  
### `disk_clean_up`
This playbook will clean up the disk on a device. Used primaraily for prestaging to ensure a dveice is ready to download a new image. This should be ran prior to any upload as this script will delete an image that is not currently active.
For devices in bundle mode, script will delete the following patterns (the script will not delete the currently running image):
          - '^crashinfo'
          - '\.log$'
          - '\.old$'
          - '\.prv$'
          - '\.xml$'
          - '\.bin$'
          - '\.tar$'
          
For devices in install mode, script will delete the following patterns as well as run "install remove inactive":
          - '^crashinfo'
          - '\.log$'
          - '\.old$'
          - '\.prv$'
          - '\.xml$'

Supported OS:
* IOS (bundle mode)
* IOS XE (bundle/install mode)

**Variables**
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
- `target_hosts` (required): The  groups/hosts that you'd like to run the playbook on. Example: -e 'target_hosts=switch,router' will run the playbook for all devices belongiong to groups switch or router.
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `ansible_become_password` (optional): Enable password for higher privilages, defaults to ansible_password when not defined
- `confirm` (required): When running this script, a confimation is required before deleting files, if running using passed -e, this var is required for afk operation.

**Examples**   
Cleans disk image for hosts in the c9200l, c2960x, or c9000 groups
```bash
ansible-playbook playbooks/upgrades/disk_clean_up.yml -e 'target_hosts=c9200l,c2960x,c9000' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes'
```

Output:
PLAY [Disk Clean UP Playbook] *************************************************************************************************************************************************************************************
...
REDACTED OUTPUT - Tasks in this section are unimportant
...
TASK [Show device mode] *******************************************************************************************************************************************************************************************
ok: [METCTSW-STK9A] =>
  msg: Device is running in install mode
ok: [METRO-ROMA-SW] =>
  msg: Device is running in bundle mode
ok: [REMUS] =>
  msg: Device is running in install mode
ok: [ROMULUS] =>
  msg: Device is running in install mode
...
REDACTED OUTPUT - Tasks in this section are unimportant
...
TASK [Show matched files] *****************************************************************************************************************************************************************************************
ok: [METCTSW-STK9A] =>
  msg: |-
    Found 0 matching files:
ok: [METRO-ROMA-SW] =>
  msg: |-
    Found 0 matching files:
ok: [REMUS] =>
  msg: |-
    Found 1 matching files:
    - smart_overall_health.log
ok: [ROMULUS] =>
  msg: |-
    Found 1 matching files:
    - smart_overall_health.log

TASK [Cleaning up unnecessary package files] **********************************************************************************************************************************************************************
ok: [REMUS]
ok: [ROMULUS]
ok: [METCTSW-STK9A]

TASK [Delete matching files] **************************************************************************************************************************************************************************************
ok: [ROMULUS]
ok: [REMUS]

</details>
-------------------------------------------------

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
