VERSION?=12.2
RELEASE?=RELEASE
ARCH?=arm64
COMPRESS?=lz4

NAME=yetibsd
ZPOOL?=$(NAME)-pool

HOST=https://download.freebsd.org/ftp/releases


WORKDIR?=$(.CURDIR)/work

LIVECD=$(WORKDIR)/$(ZPOOL)
CDROOT=$(LIVECD)/cdroot
UZIP=$(WORKDIR)/uzip
ISO="$(LIVECD)/iso"

RAMDISK="$(CDROOT)/data/ramdisk"

CACHE=$(.CURDIR)/cache
BASE=$(CACHE)/$(ARCH)/$(VERSION)
PACKAGES=$(BASE)/packages

MD=99
MD0=md$(MD)
MDP=$(MD0)p1



all: test


test:
	@echo $(WORKDIR)




clean:
	@echo cleaning...
	umount $(UZIP)/var/cache/pkg >/dev/null 2>/dev/null || true
	umount $(UZIP)/dev >/dev/null 2>/dev/null || true
	zpool destroy -f $(ZPOOL) >/dev/null 2>/dev/null || true
	mdconfig -d -u $(MD) >/dev/null 2>/dev/null || true
	rm $(WORKDIR)/pool.img >/dev/null 2>/dev/null || true
	rm -rf $(CDROOT) >/dev/null 2>/dev/null || true


workspace:
	mkdir -p "$(WORKDIR)"
	mkdir -p "$(UZIP)"
	mkdir -p "$(BASE)"
	mkdir -p "$(PACKAGES)"
	# mkdir -p "$(RAMDISK)/dev"
	# mkdir -p "$(RAMDISK)/etc"
	# mkdir -p "$(ISO)"

	truncate -s 3g "$(WORKDIR)/pool.img"
	mdconfig -f "$(WORKDIR)/pool.img" -u $(MD)
	gpart create -s GPT $(MD0)
	gpart add -t freebsd-zfs $(MD0)

	zpool create $(ZPOOL) /dev/$(MDP)
	# TODO: add a separate log device
	zfs set mountpoint="$(UZIP)" $(ZPOOL)
	zfs set atime=off $(ZPOOL)
	zfs set recordsize=1m $(ZPOOL)
	zfs set compression="$(COMPRESS)" $(ZPOOL)



$(BASE)/base.txz:
	fetch $(HOST)/$(ARCH)/$(VERSION)-$(RELEASE)/base.txz -o $(BASE)/base.txz
	tar -zxvf $(BASE)/base.txz		-C $(UZIP)

$(BASE)/kernel.txz:
	fetch $(HOST)/$(ARCH)/$(VERSION)-$(RELEASE)/kernel.txz -o $(BASE)/kernel.txz
	tar -zxvf $(BASE)/kernel.txz	-C $(UZIP)

extractbase:
	tar -zxvf $(BASE)/base.txz		-C $(UZIP)
	tar -zxvf $(BASE)/kernel.txz	-C $(UZIP)

base: $(BASE)/base.txz
base: $(BASE)/kernel.txz


cleanbase:
	umount $(UZIP)/var/cache/pkg	>/dev/null 2>/dev/null	|| true
	umount $(UZIP)/dev				>/dev/null 2>/dev/null	|| true
	rm -r  $(UZIP)			|| true
	rm $(BASE)/base.txz		|| true
	rm $(BASE)/kernel.txz	|| true




packages:
	cp /etc/resolv.conf $(UZIP)/etc/resolv.conf
	mkdir $(UZIP)/var/cache/pkg
	mount_nullfs $(PACKAGES) $(UZIP)/var/cache/pkg
	mount -t devfs devfs $(UZIP)/dev



extract: extractbase



#base:
#	touch $(uzip)/etc/fstab


#cleanup
#workspace
#repos
#pkg
#base
#packages
#rc
#user
#dm
#uzip
#ramdisk
#boot
#image
