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
    - [`prestage-ios_iosxe`](#prestage-ios_iosxe)
    - [`tacacs`](#tacacs)
    - [`radius`](#radius)
  - [Procedures](#procedures)
    - [Upgrade Prestage](#upgrade-prestage)
    - [Configure AAA TACACS](#configure-aaa-tacacs)
    - [Configure AAA RADIUS](#configure-aaa-radius)

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

You can target specific hosts/groups to run the playbook. You can use a single group, multiple groups, single host, multiple hosts, combination groups/hosts. You split the differing variables with a comma (,) no space, for example:
Single Group: switches
Multiple Group: switches,routers,firewalls
Single Host: switch1
Multiple Host: switch1,switch2,router2
Combination: switches,router1

When using a group, all devices associated to that group will be targeted. 

When running playbooks, if -l or --limit is omitted from teh command, all hosts will be targeted by the playbook. 

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

#### Inventory Troubleshooting
* For many issues that may come up regarding inventory, the number 1 thing to check is that the inventory.xlsl exists in the inventory folder. 

## Playbooks
<details>
<summary>update_snmp_acl</summary>
  
### `update_snmp_acl`
This playbook updates the SNMP ACL on one or more devices to allow this host's IP address.

**Supported OS:**   
* IOS
* IOS/XE
* NX-OS
* FTD (via FDM)

**Variables**   
- `snmp_string` (required) The SNMP string to use
- `enable_secret` (Optional): enable secret if device requires it
- `collector_ips` (Optional): List type. Allows for multiple IP addresses of collectors to be passed separated by commas
- `collector_ip` (Optional): Allows for single IP addresses to be passed

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
- `enable_secret` (optional): enable secret if device requires it
  
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

**Supported OS:**  
* IOS
* IOS/XE
* NX-OS

**Variables**   
- `snmp_string` (required): The SNMP string to use
- `enable_secret` (optional): enable secret if device requires it
  
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

**Supported OS**    
* IOS
* IOS/XE

**Variables**   
- `acl_ips`: (Required if remove not set): Type List of string. These are the subnets that will be put into the ACL. Example. acl_ips=["10.16.0.0 0.0.255.255", "10.17.0.0 0.0.255.255"]
- `acl_name`: (Required if remove not set): Type string. The name of the ACL that will be applied to the http-server
- `remove`: (Required if acl_ips and acl_name are not set): Type bool. Set to "true" to remove the http-server config from the switch. This is mutually exclusive to the acl_ips and acl_name variables. Do not set this and acl_ips/acl_name.
- `enable_secret`: (Optional): enable secret if device requires it
  
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
This playbook shows the platform series from inventory, i.e. c9000. It is used as a pre step for upgrades and helps to minimize the amount of discovery needed to prepare for downloading images.

**Supported OS:**   
* All

**Variables**   
Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will return the platform series for all devices belonging to groups switch or router.

**Examples**   
Shows platform series for all hosts/groups
```bash
ansible-playbook playbooks/upgrades/get_platform_series.yml
```
Shows platform series for switch/router group
```bash
ansible-playbook playbooks/upgrades/get_platform_series.yml -l 'switch,router'
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
The task named "Show platform series for selected hosts/groups" will show the combined platform series for the hosts/groups.

In this example, you would then go to Cisco software download and download the image for 2960x, c9000, and asa5506. Downloading those 3 will cover all devices' software requirements.
</details>
-------------------------------------------------
<details>
<summary>disk_clean_up</summary>
  
### `disk_clean_up`
This playbook will clean up the disk on a device. Used primarily for prestaging to ensure a device is ready to download a new image. This should be ran prior to any upload as this script will delete an image that is not currently active.
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

**Supported OS:**   
* IOS (bundle mode)
* IOS XE (bundle/install mode)

**Variables**  
- If these variables are not passed in via the -e argument, they will be prompted for during the script execution
- Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will clean the disk for all devices belonging to groups switch or router.
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `enable` (optional): Enable password for higher privilages, defaults to ansible_password when not defined
- `confirm` (required): When running this script, a confirmation is required before deleting files, if running using passed -e, this var is required for afk operation.

**Examples**   
Cleans disk image for hosts in the c9200l, c2960x, or c9000 groups
```bash
ansible-playbook playbooks/upgrades/disk_clean_up.yml -l 'c9200l,c2960x,c9000' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes'
```

Output:
```bash
PLAY [Disk Clean UP Playbook] *************************************************************************************************************************************************************************************
...
REDACTED OUTPUT - Tasks in this section are unimportant
...
TASK [Show device mode] *******************************************************************************************************************************************************************************************
ok: [sw1] =>
  msg: Device is running in install mode
ok: [sw2] =>
  msg: Device is running in bundle mode
ok: [sw3] =>
  msg: Device is running in install mode
ok: [sw4] =>
  msg: Device is running in install mode
...
REDACTED OUTPUT - Tasks in this section are unimportant
...
TASK [Show matched files] *****************************************************************************************************************************************************************************************
ok: [sw1] =>
  msg: |-
    Found 0 matching files:
ok: [sw2] =>
  msg: |-
    Found 0 matching files:
ok: [sw3] =>
  msg: |-
    Found 1 matching files:
    - smart_overall_health.log
ok: [sw4] =>
  msg: |-
    Found 1 matching files:
    - smart_overall_health.log

TASK [Cleaning up unnecessary package files] **********************************************************************************************************************************************************************
ok: [sw1]
ok: [sw2]
ok: [sw3]

TASK [Delete matching files] **************************************************************************************************************************************************************************************
ok: [sw3]
ok: [sw4]
```
Install remove inactive is being run on dveices in install mode under the task named "Cleaning up unnecessary package files"

</details>
-------------------------------------------------
<details>
<summary>prestage-ios_iosxe</summary>
  
### `prestage-ios_iosxe`
This playbook will upload the required image via http and verify md5 of the file. The playbook will first check to make sure the device is not currently running the target version then make sure that the device has enough disk space before attempting the upload. Playbook can be run multiple times on dveices due to safety checks. A previosly succesful device will not redownload the image for example.

**Summary/Overview of tasks:**  
* Server check: Ensures that the http and folder are reachable, playbook will not continue if server is not reachable.
* Backs Up device config to /opt/ansible_local/anm_itops_playbooks/backup
* Version Check: If a device is already running the target version, the device will be marked as complete.
* Disk Space Check: If a device does not have enough space for new image, it will be marked as failed. Rest of tasks will be skipped
* Check for current image in flash: Playbook will check if the software image is already on the device, if it is, it will skip upload and only verify MD5
* Upload Image: After Tasks to Asser device does not have the image, the playbook may seem to freeze, the first batch of dveices will begin the image copy and no output or progress will be shown during this time. You are free to walk away.
* Verify MD5: After upload (or if image is already on disk), the playbook will verify the image MD5. 
* Output: If all tasks complete successfully, each device will show the verified output, as well as the command needed to install/update the software for later use.

**Supported OS:**  
* IOS (bundle mode)
* IOS XE (bundle/install mode)

**Variables**  
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will prestage for all devices belonging to groups switch or router..
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `enable` (optional): Enable password for higher privilages, defaults to ansible_password when not defined
- `http_server` (required): The IP address of the http server i.e 10.10.10.10

**Examples**   
Starts prestage process for devices in the c9200l group, using http server 1.1.1.1
```bash
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l "c9200l" -e "ansible_user=user" -e 'ansible_password=password' -e "http_server=1.1.1.1"
```

Output:
```bash
PLAY [Prompt for variables if needed] *****************************************************************************************************************************************************************************
...
REDEACTED
...

TASK [Debug all device facts] *************************************************************************************************************************************************************************************
ok: [sw1] =>
  msg: |-
    Device Configuration Facts:
    ========================
    Device Mode: bundle
    Target Image: c2960x-universalk9-tar.152-7.E13.tar
    Target Image MD5: 56604f86ee9b096b3deb622b52062f6b
    Target Image Size: 41574400
    Target Image Size KB: 41574.4
    Target Version: 15.2(7)E13
    Flash Directory: flash:
    Timestamp: 2025-11-06
    Current Version: 15.2(2)E7
    IOS Type: IOS
    Device Upgraded: False
    Dir Image Check:
    Free Space: 94977024

TASK [Config Backup /opt/ansible_local/anm_itops_playbooks/backup] ************************************************************************************************************************************************
changed: [sw1]

TASK [Check running image] ****************************************************************************************************************************************************************************************
ok: [sw1] => changed=false
  msg: METRO-ROMA-SW not running target version 15.2(7)E13, current version is 15.2(2)E7

TASK [Assert Enough Disk Space Available] *************************************************************************************************************************************************************************
ok: [sw1] => changed=false
  msg: Enough disk space is available to accommodate target image.

TASK [Assert flash: does NOT contain target image before copy] ****************************************************************************************************************************************************
ok: [sw1] => changed=false
  msg: 'c2960x-universalk9-tar.152-7.E13.tar NOT in flash:'

TASK [Copy IOSXE image file via HTTP] *****************************************************************************************************************************************************************************
ok: [sw1]

...
REDACTED
...

TASK [output results] *********************************************************************************************************************************************************************************************
ok: [sw1] =>
  msg: |-
    MD5 - ['Done!', 'Verified (flash:c2960x-universalk9-tar152-7E13tar) = 56604f86ee9b096b3deb622b52062f6b']
    To upgrade use: archive download-sw flash:c2960x-universalk9-tar.152-7.E13.tar

```


#### Troubleshooting
Troubleshooting can be categorized based on which task was failed for a device. For any failed device, I would create a list of failed devices, fix the issues, then run the script again for those devices.
* HTTP server check failure: Ensure that the http server is operational and working. If using IIS, make sure you can reach it successfully yourself by navigating to http://1.1.1.1/http, you should see the files listed on the browser if successful.
* Disk Space Failure: Log into the device and clean up the disk space. This can be done manually or using the disk_clean_up playbook for the hosts that failed the disk space check i.e -e 'target_hosts=switch4,router1'
* MD5 Failure: This indicates a corrupted image, best to log into dveice manually and delete the image then try again.
* Errors during Upload: If you see errors related to IO errors during the upload task, this could indicate the device is unable to reach the server. Few things to check -
  - Ensure device can reach the http server, i.e telnet 1.1.1.1 80. If not working, check for ACLs or FW that could be blocking
  - The source http client interface could be set incorrectly. You can set this manually or use the http-source-int-update playbook to automatically set an http client source interface
  - The server could have been overloaded during the operation and refused connection. If the http server has high CPU, this could cause IO errors, simply rerunning with less hosts could be successful
* Timeout or Failed to write to SSH Channel: These errors could be caused by an unreachable dveice or if uploading takes too long. Retry at a later time using same script. If issue persists, these devices will need to be manually prestaged.

</details>
-------------------------------------------------
<details>
<summary>http-source-int-update</summary>
  
### `http-source-int-update`
This playbook will dynamically set the http client source interface based on whatever interface is using the SSH ip address. For example, if you successfully SSH to IP address 1.1.1.1, that means more than likely that the interface that is assigned with that IP can be used as the http client source. Running this on client devices will not break any other functionality since the http client source is only used for copy operations, which we own.

**Supported OS:**  
* IOS
* IOS XE

**Variables**  
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update http client source interface for all devices belonging to groups switch or router.
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined

**Examples**   
Updates the http client source interface to interface assigned with the IP used to successfully log into the device
```bash
ansible-playbook playbooks/upgrades/http-source-int-update.yml -e "target_hosts=c9200l" -e "ansible_user=user" -e 'ansible_password=password'
```

Output:
```bash
PLAY [Prompt for variables if needed] *****************************************************************************************************************************************************************************
...
REDACTED
...
TASK [Set HTTP Source] ********************************************************************************************************************************************************************************************
changed: [sw1]
changed: [sw2]

TASK [Verify HTTP source interface configuration (IOS)] ***********************************************************************************************************************************************************
ok: [sw1]
ok: [sw2]

TASK [Consolidate http_config_verify results] *********************************************************************************************************************************************************************
ok: [sw1]
ok: [sw2]

TASK [Display verification results] *******************************************************************************************************************************************************************************
ok: [sw1] =>
  msg: |-
    Configuration Verification for 1.1.1.1:
    - Interface used: Loopback0
    - Configuration found: ip http client source-interface Loopback0
    - Status: SUCCESS
ok: [sw2] =>
  msg: |-
    Configuration Verification for 2.2.2.2:
    - Interface used: Loopback0
    - Configuration found: ip http client source-interface Loopback0
    - Status: SUCCESS
```
</details>
-------------------------------------------------
<details>
<summary>tacacs</summary>

### `tacacs`
This playbook will dynamically configure TACACS on devices.

**Summary/Overview of tasks:**  
* Configures AAA new-model if not configured - required for devices that are newly being configured
* Grabs any current TACACS related configuration
* Configures Specified tacacs servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml` - Ensure to update aaa-servers.yml before attempting to run the playbook
* Configures TACACS group with the organization_prefix + TACACS, example: ANM-TACACS. Places the configured TACACS servers in the group
* Configures method lists with organization_prefix and the newly created TACACS group For example:
```bash
aaa authentication login ANM_authc group ANM-TACACS local enable
aaa authentication enable default group ANM-TACACS enable
aaa authorization exec ANM_authz group ANM-TACACS local if-authenticated
aaa accounting commands 1 default start-stop group ANM-TACACS
aaa accounting commands 15 default start-stop group ANM-TACACS
```
* Configures the VTY lines with the authentic ation and autjorization method lists, for example:
```
line vty 0 15
login authentication ANM_authc
authorization exec ANM_authz
```
* Removes old and depracted tacacs-server commands - tacacs-server commands are being removed in future releases, this task removes them and ensure we are only using named configs
* Shows output after configuring

**Supported OS:**  
* IOS
* IOS XE

**Variables**
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update TACACS for all devices belonging to groups switch or router.
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
- `organization_prefix` (required): Prefix that will be appended to the TACACS group and AAA method lists
- `tacacs_key` (required): The PSK used for the TACACS server

**Examples**   
Configures TACACS on a single device. 
```bash
ansible-playbook playbooks/configuration/aaa/tacacs.yml -l 'sw1' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
```

Output:
```bash
```
</details>
-------------------------------------------------
<details>
<summary>radius</summary>

### `radius`
This playbook will dynamically configure TACACS on devices.

**Summary/Overview of tasks:**  
* Configures AAA new-model if not configured - required for devices that are newly being configured
* Grabs any current RADIUS related configuration
* Configures Specified radius servers in `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml` - Ensure to update aaa-servers.yml before attempting to run the playbook
* Configures RADIUS group with the organization_prefix + RADIUS, example: ANM-RADIUS. Places the configured RADIUS servers in the group
* Configures method lists with organization_prefix and the newly created TACACS group For example:
```bash
aaa authentication login ANM_authc_radius group ANM-RADIUS local enable
aaa authentication enable default group ANM-RADIUS enable
aaa authorization exec ANM_authz__radius group ANM-RADIUS local if-authenticated
aaa accounting commands 1 default start-stop group ANM-RADIUS
aaa accounting commands 15 default start-stop group ANM-RADIUS
```
* Configures the VTY lines with the authentic ation and autjorization method lists, for example:
```
line vty 0 15
login authentication ANM_authc
authorization exec ANM_authz
```
* Removes old and depracted tacacs-server commands - tacacs-server commands are being removed in future releases, this task removes them and ensure we are only using named configs
* Shows output after configuring

**Supported OS:**  
* IOS
* IOS XE

**Variables**
If these variables are not passed in via the -e argument, they will be prompted for during the script execution
Remember to use -l or --limit to run playbook on specific hosts/groups: Example: -l 'switch,router' will update RADIUS for all devices belonging to groups switch or router.
- `ansible_user` (required): Username to log in to devices
- `ansible_password` (required): Password to log in to devices (if a device does not log into a dveice in enable, this same password will be tried for enable mode)
- `enable` (optional): Enable password for higher privileges, defaults to ansible_password when not defined
- `organization_prefix` (required): Prefix that will be appended to the RADIUS group and AAA method lists
- `radius_key` (required): The PSK used for the RADIUS server
- `timeout` (optional): Timeout in seconds, defaults to 3 seconds
- `retries` (optional): Amount of times to retry, defaults to 3
- `deadtime` (optional): Amount of time in muntes before trying a server marked dead again, defaults to 10 minutes
- `configure_coa` (optional): Set to 'yes' to also confogure COA for the same radius servers using the same key. Defaults to 'no'.

**Examples**   
Configures RADIUS on a single device. 
```bash
ansible-playbook playbooks/configuration/aaa/radius.yml -l 'sw1' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=tacacs123'
```

Output:
```bash
```
</details>

## Procedures:
<details>
<summary>Upgrade Prestage</summary>
  
### Upgrade Prestage:
**1. Determine Platform Series:** First determine what platform series are available, this list will be used to download the images from Cisco
* Run the [`get_platform_series`](#get_platform_series) playbook for example: (Review section for this playbook for further options or more details)
```bash
ansible-playbook playbooks/upgrades/get_platform_series.yml  -l 'switch,router'
```
* The last task will show you a list of device platforms based on the inventory selected, for example:

```bash
TASK [Show platform series for selected hosts/groups] ******************************************************************
ok: [ABQ-CORE-01] =>
  msg: |-
    Platform series in use:
    - c2960cx
    - c2960x
    - c3560cx
    - c9000
    - isr4300
```

**2. Download Software and Update images.yml:** Go to Cisco download page and download software for each of the displayed platforms.
NOTE: Make sure that you download .tar files for any IOS device to ensure that archive download-sw can be used:
- 2960 devices
- 3560 devices
- 3750 devices
   * Open up images.yml in Visual Studio (`/opt/ansible_local/anm_itops_playbooks/upgrades/vars`).
       * NOTE: If images.yml does not exist, make a copy of images-sample.yml within the same folder and rename to images.yml
   * Make sure to grab the following information while in the download page for the software and fill out the appropriate device platform in images.yml. MD5 and Image size can be obtained by hovering over the image name.
    - Image Name
    - Image MD5
    - Image Size in Bytes
    - Image Code - The version number of the image, IOS XE is usually in this format: xx.xx.xx so 17.09.08 for example. IOS usually has a format of xx.x(x)Ex, you can see IOS code in correct format on the release notes section of the download page.
  
   * Example info filled in for 2960x in images.yml

    ```yaml
    ##2960x 2960xr
    c2960x_target_image: c2960x-universalk9-mz.152-7.E13.tar
    c2960x_md5_hash: 03a1a35666ef516b35e487c31db8e9f9
    c2960x_image_size_bytes: 26796032
    c2960x_image_code: 15.2(7)E13
    ```
  * Save images.yml after all platform series info has been filled out
  * Move the downloaded images to the http folder on the desktop (if http folder is missing, refer to HTTP server set up guide to set up HTTP server on jumpbox)

 **3. Disk Clean Up (Optional):**
 * Run [`disk_clean_up`](#disk_clean_up) playbook to run through devices and clean up old images to prepare for new image, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/upgrades/disk_clean_up.yml  -l 'switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'confirm=yes' 
```
 * If any devices fail, you may need to manually clean them up

**4. Image Upload:**
* Run the [`prestage-ios_iosxe`](#prestage-ios_iosxe) playbook, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l 'switch,router' -e 'ansible_user=user' -e 'ansible_password=password' -e 'http_server=172.22.15.110'
```
* If any devices fail, review the failures and fix issues (such as cleaning disk space or fixing http client source interface), refer to the troubleshooting section for this playbook for further tips.
* After troubleshooting failed devices, you can run playbook again on the failed devices directly, for example:
```
ansible-playbook playbooks/upgrades/prestage-ios_iosxe.yml -l 'sw1,rtr02' -e 'ansible_user=user' -e 'ansible_password=password' -e 'http_server=172.22.15.110'
```
* If devices continue to fail, you will need to manually prestage those devices
</details>
-------------------------------------------------
<details>
<summary>Configure AAA TACACS</summary>
  
### Configure AAA TACACS
**1. Update aaa-servers.yml:** Navigate to `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml`
* If aaa-servers.yml is not in the folder, you can copy aaa-servers-sample.yml, and rename it to aaa-server.yml. Open the file in Visual Studio
* Fill in the info for the TACACS servers under the `tacacs_servers` block. The only required information to fill out is name: and address:
* Multple servers can be added by copying from -name and pasting under port:, for example:
```yaml
tacacs_servers:
  - name: server1
    address: 4.4.4.4
    key: "{{ tacacs_key }}"
    port: 49
  - name: server2
    address: 5.5.5.5
    key: "{{ tacacs_key }}"
    port: 49
```
* The above will be used to configure 2 servers on devices, any servers that are not in this list will be removed from the device. 

**2. Run TACACS playbook:**   
* Run [`tacacs`](#tacacs) playbook to run through devices and configure the specified tacacs servers, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/configuration/aaa/tacacs.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
```
 * Be aware that this playbook is meant to be a sort of source of truth. The script will always ensure that **ONLY** the servers in the aaa-servers list are configured.

**To remove servers:**   
* Servers can be removed by updating `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml` then rerunning the playbook
```
ansible-playbook playbooks/configuration/aaa/tacacs.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'tacacs_key=tacacs123'
```
</details>
-------------------------------------------------
<details>
<summary>Configure AAA TACACS</summary>
  
### Configure AAA RADIUS
**1. Update aaa-servers.yml:** Navigate to `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml`
* If aaa-servers.yml is not in the folder, you can copy aaa-servers-sample.yml, and rename it to aaa-server.yml. Open the file in Visual Studio
* Fill in the info for the TACACS servers under the `radius_servers` block. The only required information to fill out is name: and address:
* Multple servers can be added by copying from -name and pasting under port:, for example:
```yaml
radius_servers:
  - name: server1
    address: 4.4.4.4
    key: "{{ radius_key }}"
    auth_port: 1812
    acct_port: 1813
  - name: server2
    address: 5.5.5.5
    key: "{{ radius_key }}"
    auth_port: 1812
    acct_port: 1813
```
* The above will be used to configure 2 servers on devices, any servers that are not in this list will be removed from the device. 

**2. Run RADIUS playbook:**   
* Run [`radius`](#radius) playbook to run through devices and configure the specified tacacs servers, for example:  (Review section for this playbook for further options or more details)
```
ansible-playbook playbooks/configuration/aaa/radius.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=tacacs123'
```
 * Be aware that this playbook is meant to be a sort of source of truth. The script will always ensure that **ONLY** the servers in the aaa-servers list are configured.

**To remove servers:**   
* Servers can be removed by updating `/opt/ansible_local/anm_itops_playbooks/playbooks/configuration/aaa/vars/aaa-servers.yml` then rerunning the playbook
```
ansible-playbook playbooks/configuration/aaa/radius.yml -l 'switch' -e 'organization_prefix=ANM' -e 'ansible_user=user' -e 'ansible_password=password' -e 'radius_key=tacacs123'
```
</details>

