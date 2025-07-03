# PfSense

## What is it?

PfSense is an open source operating system based on FreeBSD, specifically designed to function as a firewall and router. It offers a complete network security solution with advanced features such as:

- Stateful Firewall
- Routing and NAT
- VPN (IPSec, OpenVPN, WireGuard)
- Content filtering
- Load balancing
- Traffic monitoring
- User authentication
- DDoS protection

Its popularity comes from its stability, security, and ease of use thanks to its intuitive web interface.

## Creating the PfSense Image

1. Download the official image from [PfSense](https://www.pfsense.org/download/)
2. Use a virtualization tool (e.g., VirtualBox)
   ```
   WARNING: The virtual hard disk created must be:
        - in VHD format
        - fixed size
   ```
3. Boot from the previously downloaded image to install the OS
4. Perform a first boot of the machine to initialize it, making sure to properly remove the installation ISO
5. Perform basic initial configuration
6. Go to the VM directory then copy the VHD, this is the image that will be used for Azure

## Configuration

### VM Configuration

Once the first initialization of the VM is completed, it is necessary to perform some operations so that the image used on the Azure architecture is fully functional.

#### Boot Configuration

Before continuing, you will need to create a file named `loader.conf.local` to virtualize a physical port to communicate with the machine via serial input.

```sh
# Serial console configuration for Azure
boot.config="-S115200 -h"
comconsole_speed="115200"
comconsole_port="0x3F8"  # COM1 port address
console="comconsole,vidconsole"
boot_multicons="YES"
boot_serial="YES"

# Force kernel output to serial console
kern.cam.boot_delay=10000  # Give more time for disk detection
kern.hz="100"  # Recommended for virtual environments

# Azure/Hyper-V specific parameters
hw.pci.enable_msix="0"  # Disable MSI-X which can cause problems in Hyper-V
hw.pci.enable_msi="0"   # Disable MSI which can cause problems in Hyper-V
```

This configuration will be very useful to continue configuring the machine once it is deployed on the Azure architecture.

### SSH Configuration

To add an SSH public key in the pfSense graphical interface, here is the procedure to follow:

1. Connect to the pfSense web interface with your username and password
2. Go to the "System" menu
3. Select "User Manager"
4. Find the user for whom you want to add an SSH key and click on the edit icon (pencil)
5. Scroll down to the "Keys" section
6. In the "Authorized keys" field, paste your SSH public key
7. Click "Save" to validate the changes

Make sure your SSH public key is in the correct format (usually starts with "ssh-rsa" or "ssh-ed25519" followed by a long string of characters).

Don't forget to also check that the SSH service is enabled in "System" > "Advanced" > "Admin Access" tab and that firewall rules allow SSH access. Also verify that the web protocol used is HTTPS. Click Save to validate the changes

Make sure to disable IPv6 for the LAN interface in "Interfaces" > "LAN" then validate.

Add a rule for incoming traffic, for this go to Firewall > Rules then select the WAN tab. Click Add to add a new rule:

```
* Action : Pass
* Interface : WAN
* Address Family : IPv4
* Protocol : Any
* Source : any
* Destination : This Firewall (self)
* Description : ""
```

Click Save
Click Add again

```
* Action : Block
* Interface : WAN
* Address Family : IPv4
* Protocol : TCP
* Source : any
* Destination : Any
* Description : "Block all on WAN"
```

Click Save

Add a port forwarding rule in the "Firewall" > "NAT" > "Port Forward" menu:

HTTP / HTTPS port forward:
```
* Interface : WAN
* Protocol : TCP
* Redirect target IP : 10.0.1.20
* Redirect target port : 80
* Destination port range : 80
* Description : "Port forward HTTP to GLPI"
```
```
* Interface : WAN
* Protocol : TCP
* Redirect target IP : 10.0.1.20
* Redirect target port : 443
* Destination port range : 443
* Description : "Port forward HTTPS to GLPI"
```
Leave "Add associated filter rule" checked (it will automatically create the corresponding firewall rule).

### Azure Deployment

When the PfSense VM is deployed in the cloud:
1. Access its monitoring interface via Azure
2. Go to the `Boot Diagnostics` menu
3. Go to settings:
   - Select the correct storage account
   - Save the changes

From now on, you will have access to a terminal of your VM via the serial console. You will need it to configure the **WAN** and **LAN** interfaces.
