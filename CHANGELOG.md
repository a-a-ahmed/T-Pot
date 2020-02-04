# Changelog

## 20190626
- **HPFEEDS Opt-In commandline option**
  - Pass a hpfeeds config file as a commandline argument
  - hpfeeds config is saved in `/data/ews/conf/hpfeeds.cfg`
  - Update script restores hpfeeds config

## 20190604
- **Finalize Fatt support**
  - Build visualizations, searches, dashboards
  - Rebuild index patterns
  - Some finishing touches

## 20190601
- **Start supporting Fatt, remove Glastopf**
  - Build Dockerfile, Adjust logstash, installer, update and such.
  - Glastopf is no longer supported within T-Pot

## 20190528+20190531
- **Increase total number of fields**
  - Adjust total number of fileds for logstash templae from 1000 to 2000.

## 20190526
- **Fix build for Cowrie**
  - Upstream changes required a new package `py-bcrypt`.

## 20190525
- **Fix build for RDPY**
  - Building was prevented due to cache error which occurs lately on Alpine if `apk` is using `--no-ache' as options.

## 20190520
- **Adjust permissions for /data folder**
  - Now it is possible to download files from `/data` using SCP, WINSCP or CyberDuck.

## 20190513
- **Added Ansible T-Pot Deployment on Open Telekom Cloud**
  - Reusable Ansible Playbooks for all cloud providers
  - Example Showcase with our Open Telekom Cloud

## 20190511
- **Add hptest script**
  - Quickly test if the honeypots are working with `hptest.sh <[ip,host]>` based on nmap.

## 20190508
- **Add tsec / install user to tpot group**
  - For users being able to easily download logs from the /data folder the installer now adds the `tpot` or the logged in user (`who am i`) via `usermod -a -G tpot <user>` to the tpot group. Also /data permissions will now be enforced to `770`, which is necessary for directory listings.

## 20190502
- **Fix KVPs**
  - Some KVPs for Cowrie changed and the tagcloud was not showing any values in the Cowrie dashboard.
  - New installations are not affected, however existing installations need to import the objects from /opt/tpot/etc/objects/kibana-objects.json.zip.
- **Makeiso**
  - Move to Xorriso for building the ISO image.
  - This allows to support most of the Debian based distros, i.e. Debian, MxLinux and Ubuntu.

## 20190428
- **Rebuild ISO**
  - The install ISO needed a rebuilt after some changes in the Debian mirrors.
- **Disable Netselect**
  - After some reports in the issues that some Debian mirrors were not fully synced and thus some packages were unavailable the netselect-apt feature was disabled.

## 20190406
- **Fix for SSH**
  - In some situations the SSH Port was not written to a new line (thanks to @dpisano for reporting).
- **Fix race condition for apt-fast**
  - Curl and wget need to be installed before apt-fast installation.

## 20190404
- **Fix #332**
  - If T-Pot, opposed to the requirements, does not have full internet access netselect-apt fails to determine the fastest mirror as it needs ICMP and UDP outgoing. Should netselect-apt fail the default mirrors will be used.
- **Improve install speed with apt-fast**
  - Migrating from a stable base install to Debian (Sid) requires downloading lots of packages. Depending on your geo location the download speed was already improved by introducing netselect-apt to determine the fastest mirror. With apt-fast the downloads will be even faster by downloading packages not only in parallel but also with multiple connections per package.
