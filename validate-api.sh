#!/bin/bash
PROJECT_PATH=$1
ERRORS=0

echo "🔎 Validando governança de APIs em $PROJECT_PATH..."

# 1️⃣ Verificar a versão global no controlador e garantir que as rotas do método sigam essa versão
CONTROLLERS=$(grep -r 'Route("api/' $PROJECT_PATH)
for CONTROLLER in $CONTROLLERS; do
  # Extrair a versão definida globalmente no controlador (por exemplo, /v1/, /v2/)
  VERSION=$(echo "$CONTROLLER" | grep -oP 'api/\K[^/]+')
  
  if [[ -z "$VERSION" ]]; then
    continue  # Ignora se não encontrar versão
  fi

  # Verifica as rotas do controlador que não são de tipo api/[controller]
  ROUTES=$(grep -r "Route(\"" $PROJECT_PATH | grep -v "api/\[controller\]" | awk -F'"' '{print $2}')
  
  for ROUTE in $ROUTES; do
    # Verifica se a versão global no controlador é usada nas rotas do controlador
    if [[ ! $ROUTE =~ "/$VERSION/" && ! $ROUTE =~ "/[a-zA-Z0-9_-]+$" ]]; then
      echo "❌ Erro: A rota '$ROUTE' no controlador não possui a versão '$VERSION' explícita."
      ERRORS=$((ERRORS+1))
    fi
  done

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

# 4️⃣ Verificar duplicidade '/api/'
for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ "/api/api/" ]]; then
    echo "❌ Erro: A rota '$ROUTE' contém '/api/' duplicado."
    ERRORS=$((ERRORS+1))
  fi
done

# 5️⃣ Verifica se o nome do controller segue a convenção (deve terminar com 'Controller')
for CONTROLLER in $(grep -r 'Controller' $PROJECT_PATH); do
  if [[ ! $CONTROLLER =~ "Controller$" ]]; then
    echo "❌ Erro: O nome do controller '$CONTROLLER' não segue a convenção 'Controller'."
    ERRORS=$((ERRORS+1))
  fi
done

# 6️⃣ Verifica se os parâmetros de rota estão em kebab-case
for ROUTE in $ROUTES; do
  # Extrai parâmetros de rota entre chaves
  PARAMS=$(echo $ROUTE | grep -oP '{\K[^}]+')

  # Verifica se o parâmetro não está em kebab-case (letras maiúsculas)
  if [[ $PARAMS =~ [A-Z] ]]; then
    echo "❌ Erro: O parâmetro '$PARAMS' na rota '$ROUTE' não está em kebab-case."
    ERRORS=$((ERRORS+1))
  fi
done

# 7️⃣ Verifica se as rotas possuem tipos de resposta adequados, ignorando linhas comentadas
for ROUTE in $(grep -r 'Route("' $PROJECT_PATH); do
  # Ignora linhas comentadas (que começam com //)
  if [[ ! "$ROUTE" =~ "//" ]]; then
    # Verifica se a rota não possui a declaração de ProducesResponseType
    if [[ ! "$ROUTE" =~ "ProducesResponseType" ]]; then
      echo "❌ Erro: A rota '$ROUTE' não tem tipos de resposta padrão definidos."
      ERRORS=$((ERRORS+1))
    fi
  fi
done

# Finalizar com erro se houverem falhas
if [ $ERRORS -gt 0 ]; then
  echo "⛔ Validação falhou com $ERRORS erros."
  exit 1
else
  echo "✅ Validação concluída sem erros."
fi
