#### Compiling

Since this tiny application is written in assembly and make no use of any
toolchain-provided header or libraries (not even startfiles), you can use
basically any arm-gcc toolchain. By default it expects an arm-linux-gnueabihf
toolchain to be installed, but you can override this in the makefile or using a
``CROSS_COMPILE=`` argument to make.

Output files produced are:
* ``demo.elf`` suitable for JTAG upload and debugging
* ``demo.bin`` suitable for peripheral boot (UART, Ethernet, USB) and XIP
* ``demo.MLO`` suitable for memory boot (μSD, eMMC, SPI, NAND)
* ``demo.img`` suitable for writing directly to μSD or eMMC

#### Booting: μSD/eMMC

Boot ROM checks for the presence of a raw mmc boot header in sectors 0, 256,
512, and 768. If found, it expects the MLO to be located starting at the next
sector. If none of the four locations have a valid image, ROM proceeds to check
for a FAT filesystem (either whole-card or in a partition marked
'active'/bootable). The MLO should be located in a file named "MLO" in the root
of the filesystem.

**Note:** Contrary to what the AM335x TRM used to indicate (prior to rev M),
raw MMC boot also works for SD cards, not just for eMMC.

##### Example (raw mmc boot, prefab image)

**Caution:** This destroys existing contents of the card.

```bash
dev=/dev/mmcblk0

dd if=demo.img of=$dev
```

##### Example (raw mmc boot)

**Caution:** This overwrites sectors 1 and 2 of the card and may overwrite any
existing bootloader.  It should not affect any existing partitions that start
at sector 3 or higher.

```bash
dev=/dev/mmcblk0
sector=0

dd if=extra/raw-mmc-header.img of=$dev seek=$sector
dd if=demo.MLO of=$dev seek=$(( $sector + 1 ))
```

Note: a raw MMC header in sector 0 can peacefully coexist with a partition
table, provided adequate free space is available between the partition table
and the first partition to accomodate the MLO data. The procedure above will
not damage any existing partition table, nor should the raw mmc header get
damaged by repartitioning.

##### Example (FAT partitioned)

**Caution:** This destroys existing contents of the card.

```bash
dev=/dev/mmcblk0
mountpoint=/mnt/tmp

echo "type=0c,bootable" | sfdisk $dev
mkfs.fat ${dev}p1

mount ${dev}p1 $mountpoint
cp demo.MLO $mountpoint/MLO
umount $mountpoint
```
#### Booting: Ethernet/USB

Boot ROM tries to download a peripheral boot image using BOOTP and TFTP. See
``extra/dnsmasq.conf`` for an example configuration for dnsmasq, which can
perform both functions at the same time.

In case of USB, the device enumerates as an RNDIS network interface, after
which it proceeds the same as Ethernet.
