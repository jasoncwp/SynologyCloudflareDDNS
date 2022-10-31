chmod 700 /sbin/cloudflareddns.sh
cp /sbin/cloudflareddns.sh /sbin/cloudflareddns2.sh 

echo [Cloudflare] >> /etc.defaults/ddns_provider.conf
echo "        modulepath=/sbin/cloudflareddns.sh" >> /etc.defaults/ddns_provider.conf
echo "        queryurl=https://www.cloudflare.com/" >> /etc.defaults/ddns_provider.conf
echo [Cloudflare2] >> /etc.defaults/ddns_provider.conf
echo " modulepath=/sbin/cloudflareddns2.sh" >> /etc.defaults/ddns_provider.conf
echo " queryurl=https://www.cloudflare.com/" >> /etc.defaults/ddns_provider.conf