#!/bin/bash

# Configurações de ambiente
AWS_REGION="us-east-1"
REPO_DIR="Security-Control-Plane"
SCRIPTS_DIR="$REPO_DIR/scripts"
RULES_FILE="$SCRIPTS_DIR/remediate_map.yaml"
PLAN_OUTPUT="./remediation_plan.yaml"

echo "===================================================="
echo " AWS Security Control Plane Automation Suite "
echo "===================================================="

# Função interna para aplicar pseudo-anonimização nos arquivos gerados
anonimize_file() {
    local target_file="$1"
    if [ -f "$target_file" ]; then
        echo "-> Anonimizando dados sensíveis em: $target_file"
        
        # 1. Mascara IDs de conta AWS (12 dígitos numéricos sequenciais)
        sed -i -E 's/[0-9]{12}/123456789012/g' "$target_file"
        
        # 2. Ofusca nomes de recursos comuns/ambientes que possam aparecer em caminhos de ARNs
        sed -i -E 's/arn:aws:([a-zA-Cal-z0-9_-]+):([a-z0-9_-]+):123456789012:([^ \"]+)/arn:aws:\1:\2:123456789012:resource-masked/g' "$target_file"
        
        # 3. Anonimiza e-mails ou IDs de usuários específicos se houver
        sed -i -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/user@masked-domain.local/g' "$target_file"
    fi
}

# Se o usuário passou um arquivo por argumento na CLI
if [ ! -z "$1" ]; then
    INPUT_YAML="$1"
    echo "-> Utilizando arquivo YAML fornecido via CLI: $INPUT_YAML"
    
    if [ ! -f "$INPUT_YAML" ]; then
        echo "Erro: O arquivo especificado '$INPUT_YAML' não existe."
        exit 1
    fi
else
    # 1. FASE 00: SCAN
    echo -e "\n[1/3] Executando SCAN (Buscando novos findings no Security Hub)..."
    SCAN_LOG=$(python3 "$SCRIPTS_DIR/00_securityhub_scan.py" --region "$AWS_REGION" --output-dir ".")
    echo "$SCAN_LOG"
    
    INPUT_YAML=$(ls -1td ./202*/*.yaml 2>/dev/null | head -n 1)

    if [ -z "$INPUT_YAML" ]; then
        echo "Erro: Nenhum arquivo YAML de scan foi encontrado."
        exit 1
    fi
    
    # Aplica anonimização direto no output bruto do Scan
    anonimize_file "$INPUT_YAML"
    echo "-> Artefato de entrada preparado e mascarado: $INPUT_YAML"
fi

# 2. FASE 01: PLAN
echo -e "\n[2/3] Executando PLAN (Gerando plano de ação)..."
python3 "$SCRIPTS_DIR/01_identity_plan.py" --input-yaml "$INPUT_YAML" --rules "$RULES_FILE" --output-yaml "$PLAN_OUTPUT" \
  2>/dev/null || \
python3 "$SCRIPTS_DIR/01_securityhub_plan.py" --input-yaml "$INPUT_YAML" --rules "$RULES_FILE" --output-yaml "$PLAN_OUTPUT"

# Aplica anonimização no artefato de plano gerado
anonimize_file "$PLAN_OUTPUT"

# 3. FASE 02: REMEDIATE
echo -e "\n[3/3] Executando REMEDIATE (Modo Simulação / Dry-Run)..."
python3 "$SCRIPTS_DIR/02_securityhub_remediate.py" \
    --region "$AWS_REGION" \
    --yaml "$PLAN_OUTPUT" \
    --mode dry-run

echo -e "\n===================================================="
echo " Execução finalizada! Tudo mascarado de forma segura. "
echo " Plano salvo em: $PLAN_OUTPUT "
echo "===================================================="
