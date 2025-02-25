#!/bin/bash
PROJECT_PATH=$1
ERRORS=0

echo "🔎 Validando governança de APIs em $PROJECT_PATH..."

# 1️⃣ Validar se todas as rotas possuem versionamento (/v1/, /v2/)
ROUTES=$(grep -r 'Route("' $PROJECT_PATH | awk -F'"' '{print $2}' | grep -v "\[controller\]")
for ROUTE in $ROUTES; do
  if [[ ! $ROUTE =~ /v[0-9]+/ ]]; then
    echo "❌ Erro: A rota '$ROUTE' não possui versionamento explícito (ex: /v1/)."
    ERRORS=$((ERRORS+1))
  fi
done


# 2️⃣ Validar kebab-case nas rotas
for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ [A-Z] ]]; then
    echo "❌ Erro: A rota '$ROUTE' não está em kebab-case."
    ERRORS=$((ERRORS+1))
  fi
done

# 3️⃣ Verificar se existe um arquivo `swagger.json` (opcional)
if [ ! -f "$PROJECT_PATH/swagger.json" ]; then
  echo "⚠️ Aviso: O arquivo 'swagger.json' não foi encontrado. Certifique-se de expor o OpenAPI."
fi

# Finalizar com erro se houverem falhas
if [ $ERRORS -gt 0 ]; then
  echo "⛔ Validação falhou com $ERRORS erros."
  exit 1
else
  echo "✅ Validação concluída sem erros."
fi

for ROUTE in $ROUTES; do
  if [[ ! $ROUTE =~ ^/api/v[0-9]+/ ]]; then
    echo "❌ Erro: A rota '$ROUTE' não segue o padrão '/api/vX/'."
    ERRORS=$((ERRORS+1))
  fi
done

for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ "_" ]]; then
    echo "❌ Erro: A rota '$ROUTE' contém underscore (_). Use kebab-case."
    ERRORS=$((ERRORS+1))
  fi
done

if grep -r 'Route("' $PROJECT_PATH | grep -v 'Http' > /dev/null; then
  echo "❌ Erro: Algumas rotas não especificam métodos HTTP. Use [HttpGet], [HttpPost], etc."
  ERRORS=$((ERRORS+1))
fi

for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ "/api/api/" ]]; then
    echo "❌ Erro: A rota '$ROUTE' contém '/api/' duplicado."
    ERRORS=$((ERRORS+1))
  fi
done

# Verifica se o nome do controller segue a convenção (deve terminar com 'Controller')
for CONTROLLER in $(grep -r 'Controller' $PROJECT_PATH); do
  if [[ ! $CONTROLLER =~ "Controller$" ]]; then
    echo "❌ Erro: O nome do controller '$CONTROLLER' não segue a convenção 'Controller'."
    ERRORS=$((ERRORS+1))
  fi
done

# Verifica se os parâmetros de rota estão em kebab-case
for ROUTE in $ROUTES; do
  # Extrai parâmetros de rota entre chaves
  PARAMS=$(echo $ROUTE | grep -oP '{\K[^}]+')

  # Verifica se o parâmetro não está em kebab-case (letras maiúsculas)
  if [[ $PARAMS =~ [A-Z] ]]; then
    echo "❌ Erro: O parâmetro '$PARAMS' na rota '$ROUTE' não está em kebab-case."
    ERRORS=$((ERRORS+1))
  fi
done


# Verifica se as rotas possuem tipos de resposta adequados, ignorando linhas comentadas
for ROUTE in $(grep -r 'Route("' $PROJECT_PATH); do
  # Ignora linhas comentadas (que começam com //)
  if ! grep -q "//" <<< "$ROUTE"; then
    if [[ ! $ROUTE =~ "ProducesResponseType" ]]; then
      echo "❌ Erro: A rota '$ROUTE' não tem tipos de resposta padrão definidos."
      ERRORS=$((ERRORS+1))
    fi
  fi
done