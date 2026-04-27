FROM mysql:8.0

# Copia o script para pasta que o MySQL executa automaticamente
COPY script_nuvem_completo.sql /docker-entrypoint-initdb.d/

EXPOSE 3306