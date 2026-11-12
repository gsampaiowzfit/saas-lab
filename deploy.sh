#!/bin/bash
# ===================================================================
# Script de Deploy da Aplicação SaaS Lab no Apache Tomcat
# ===================================================================

set -e

# Nome do contexto da aplicação (URL: http://<IP>:8080/saas-lab/)
APP_NAME="saas-lab"

# Detecção automática do diretório webapps do Tomcat
if [ -d "/var/lib/tomcat9/webapps" ]; then
    TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
    TOMCAT_LIB="/var/lib/tomcat9/lib"
elif [ -d "/var/lib/tomcat10/webapps" ]; then
    TOMCAT_WEBAPPS="/var/lib/tomcat10/webapps"
    TOMCAT_LIB="/var/lib/tomcat10/lib"
elif [ -d "/opt/tomcat/webapps" ]; then
    TOMCAT_WEBAPPS="/opt/tomcat/webapps"
    TOMCAT_LIB="/opt/tomcat/lib"
elif [ -n "$CATALINA_HOME" ] && [ -d "$CATALINA_HOME/webapps" ]; then
    TOMCAT_WEBAPPS="$CATALINA_HOME/webapps"
    TOMCAT_LIB="$CATALINA_HOME/lib"
else
    echo "Diretório do Tomcat não encontrado automaticamente."
    read -p "Informe o caminho da pasta webapps do Tomcat (ex: /opt/tomcat/webapps): " TOMCAT_WEBAPPS
    TOMCAT_LIB="$(dirname "$TOMCAT_WEBAPPS")/lib"
fi

DEST_DIR="$TOMCAT_WEBAPPS/$APP_NAME"

echo "==> Iniciando deploy em: $DEST_DIR"

# Criação do diretório de destino se não existir
sudo mkdir -p "$DEST_DIR"
sudo mkdir -p "$DEST_DIR/WEB-INF"

# Cópia dos arquivos JSP e configurações
echo "==> Copiando páginas JSP e descritor web.xml..."
sudo cp index.jsp login.jsp autorizo.jsp "$DEST_DIR/"
sudo cp WEB-INF/web.xml "$DEST_DIR/WEB-INF/"

# Ajuste de permissões para o usuário tomcat
if id "tomcat" &>/dev/null; then
    sudo chown -R tomcat:tomcat "$DEST_DIR"
fi

echo "==> Verificando driver MySQL Connector/J no Tomcat..."
if [ -d "$TOMCAT_LIB" ]; then
    if ls "$TOMCAT_LIB"/mysql-connector*.jar 1> /dev/null 2>&1; then
        echo "✓ Driver MySQL JDBC já está presente na pasta lib do Tomcat."
    else
        echo "! ATENÇÃO: Driver MySQL JDBC não encontrado em $TOMCAT_LIB."
        echo "  Instalando pacote no Ubuntu/Debian..."
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y libmysql-java
            if [ -f "/usr/share/java/mysql-connector-java.jar" ]; then
                sudo ln -sf /usr/share/java/mysql-connector-java.jar "$TOMCAT_LIB/"
                echo "✓ Link simbólico criado para o driver MySQL JDBC."
            fi
        fi
    fi
fi

echo ""
echo "==================================================================="
echo "✓ Deploy concluído com sucesso!"
echo "Acesse no navegador: http://<IP_DA_VM>:8080/$APP_NAME/"
echo "==================================================================="
