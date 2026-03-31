FROM mysql:8.0

# Copia o script para pasta que o MySQL executa automaticamente
COPY script_toomate.sql /docker-entrypoint-initdb.d/

EXPOSE 3306