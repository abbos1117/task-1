FROM ubuntu:22.04

# Ishchi katalogni yaratish
WORKDIR /app
# Kerakli fayllarni konteynerga ko'chirish
COPY server_2000.py server_2001.py server_2002.py server_2003.py kali_server.py /app/
COPY server_8080 /app/server_8080
COPY client_2004 /root/client_2004
COPY kali_server.py /root/kali_server.py

COPY server_8080.service /etc/systemd/system/server_8080.service

# root foydalanuvchisini yaratish
RUN  chmod +x /root/client_2004

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    apt-get install -y python3 python3-venv python3-scapy python3-pip \
    systemd systemd-sysv ufw supervisor tzdata && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-scapy python3-pip systemd systemd-sysv ufw supervisor \
    nano vim iproute2  net-tools iputils-ping bridge-utils iptables socat netcat  \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# secureuser foydalanuvchisini yaratish
RUN useradd -m -s /bin/bash secureuser

# Katalog va fayllarga ruxsat berish
RUN chown -R root:root /app /root
RUN chmod -R 700 /app /root # secureuser katalogni ko‘ra oladi, lekin o‘qiy olmaydi
RUN find /app -type f -exec chmod 700 {} \;  # Fayllarni ishga tushirishni taqiqlash

# Scapy o'rnatish
RUN pip install scapy

# server_8080 uchun virtual muhit yaratish va kutubxonalarni o'rnatish
RUN python3 -m venv /app/server_8080/env && \
    /app/server_8080/env/bin/pip install -r /app/server_8080/requirements.txt

#RUN systemctl enable server_8080.service  #add service

# Portlarni ochish
EXPOSE 2000 2001 2002 2003 8080 9876

# UFW orqali portni ochish (UFW konteynerlarda odatda ishlatilmaydi, lekin agar kerak bo'lsa, hostda ochish tavsiya qilinadi)
#RUN apt-get update && apt-get install -y ufw && \
#    ufw allow from 0.0.0.0 to any port 9876

#ENTRYPOINT ["/sbin/init"]  #added

# Xizmatlarni ishga tushirish
CMD ["sh", "-c", "\
    python3 /app/server_2000.py --port 2000 & \
    python3 /app/server_2001.py --port 2001& \
    python3 /app/server_2002.py --port 2002& \
    python3 /app/server_2003.py --port 2003& \
    python3 /app/kali_server.py & \
    /app/server_8080/env/bin/python3 /app/server_8080/manage.py runserver 0.0.0.0:8090 & \ 
    tail -f /dev/null"]
#USER secureuser
