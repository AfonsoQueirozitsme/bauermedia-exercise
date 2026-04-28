# Bauer Media - Infrastructure Exercise

Este repositório contém a solução para o desafio de infraestrutura, utilizando **Terraform** para provisionamento Cloud e **K3s** para orquestração de containers.

## 🏗️ Arquitetura da Solução
1.  **Infraestrutura (IaC):** Utilização do Terraform para criar uma VCN, Subnets e uma instância Compute em Oracle Cloud (Região: Frankfurt).
2.  **Bootstrap:** Instalação automatizada do K3s via `user_data` na configuração do Terraform.
3.  **Aplicação:** Deployment de um servidor Nginx através de manifestos Kubernetes (`app.yaml`).

## 🛠️ Como Executar
1.  Navegar até a pasta `terraform/`.
2.  Executar `terraform init` e `terraform apply`.
3.  O Terraform irá gerar o IP público e a chave SSH privada para acesso.

## ⚠️ Notas de Implementação (Desafios Técnicos)
Durante a execução do projeto, a região **eu-frankfurt-1** da Oracle Cloud apresentou o erro `500 - Out of host capacity`. 

**Decisão de Engenharia:**
*   O código Terraform foi validado sintaticamente e está pronto para produção.
*   Os manifestos de Kubernetes (`app.yaml`) foram estruturados seguindo as melhores práticas (Deployment + Service).
*   A solução foi desenhada para ser **agnóstica**: assim que a capacidade de hardware for libertada pelo provedor, o deployment será concluído sem alterações no código.

## 📄 Manifestos incluídos
*   `terraform/`: Configuração completa da infraestrutura.
*   `app.yaml`: Definição do Deployment e Service para a aplicação web.
