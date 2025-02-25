#!/bin/bash
PROJECT_PATH=$1
ERRORS=0

echo "🔎 Validando governança de APIs em $PROJECT_PATH..."

# 1️⃣ Validar se a rota global está definida ou se cada método tem sua rota com versionamento

# Encontrar todas as rotas
ROUTES=$(grep -r 'Route("' $PROJECT_PATH | awk -F'"' '{print $2}' | grep -v "\[controller\]")

# Validar se existe uma rota global com versionamento
GLOBAL_ROUTE=$(grep -r 'Route("api/v' $PROJECT_PATH)

# Verificar se todos os métodos têm versão, caso não haja uma global
if [[ -z "$GLOBAL_ROUTE" ]]; then
  for ROUTE in $ROUTES; do
    if [[ ! $ROUTE =~ /v[0-9]+/ ]]; then
      echo "❌ Erro: A rota '$ROUTE' não possui versionamento explícito (ex: /v1/)."
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  # Se existir a rota global, verificar se todas as rotas respeitam essa versão
  VERSION=$(echo "$GLOBAL_ROUTE" | grep -oP 'api/v[0-9]+')
  for ROUTE in $ROUTES; do
    if [[ ! $ROUTE =~ "$VERSION" ]]; then
      echo "❌ Erro: A rota '$ROUTE' não segue a versão '$VERSION' definida globalmente."
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

# 2️⃣ Validar kebab-case nas rotas
for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ [A-Z] ]]; then
    echo "❌ Erro: A rota '$ROUTE' não está em kebab-case."
    ERRORS=$((ERRORS + 1))
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
    ERRORS=$((ERRORS + 1))
  fi
done

# Finalizar com erro se houverem falhas
if [ $ERRORS -gt 0 ]; then
  echo "⛔ Validação falhou com $ERRORS erros."
  exit 1
else
  echo "✅ Validação concluída sem erros."
fi
