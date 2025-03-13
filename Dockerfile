FROM ubuntu:20.04

# Systemd’ni yoqish uchun muhim sozlamalar
ENV container docker
STOPSIGNAL SIGRTMIN+3
ENV DEBIAN_FRONTEND=noninteractive

# Root userda ishlash
USER root
WORKDIR /app

# Paketlarni o‘rnatish
RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-scapy python3-pip systemd systemd-sysv ufw supervisor \
    nano vim iproute2  net-tools iputils-ping bridge-utils iptables socat netcat  \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# secureuser foydalanuvchisini yaratish
RUN useradd -m -s /bin/bash secureuser

# Katalog va fayllarga ruxsat berish
RUN chown -R root:root /app 
RUN chmod -R 710 /app  # secureuser katalogni ko‘ra oladi, lekin o‘qiy olmaydi
RUN find /app -type f -exec chmod 600 {} \;  # Fayllarni ishga tushirishni taqiqlash

# Fayllarni yuklash
COPY server_8080/ /app/server_8080/
COPY server_2000.py server_2001.py server_2002.py server_2003.py ./
COPY ./client_2004 /root/client_2004
COPY ./kali_server.py /root/kali_server.py

# Virtual muhit yaratish va kutubxonalarni o‘rnatish
RUN python3 -m venv /app/server_8080/env && \
    /app/server_8080/env/bin/pip install --no-cache-dir -r /app/server_8080/requirements.txt && \
    /app/server_8080/env/bin/pip install scapy

# UFW sozlash
RUN ufw allow 9876

# Supervisor konfiguratsiyasini qo‘shish
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# secureuser foydalanuvchisiga o‘tish
USER secureuser

EXPOSE 2000 2001 2002 2003 8080 9876

# Container ishga tushishi uchun Supervisorni ishlatish
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
