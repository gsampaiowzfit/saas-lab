# Sistema de Agendamento de Consultas Médicas

## Registro da decisão

| Campo            | Valor                                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------ |
| **Título**       | Software As A Service Infrastructure — a mini version                                                        |
| **Data**         | 08/2026                                                                                                      |
| **Status**       | Aceita                                                                                                       |
| **Responsáveis** | Gabriel Oliveira Sampaio, João Pedro Xavier Lopes, Nicolas de Sene Pinheiro, Pedro Henrique Gomes dos Santos |

## Contexto

Este mini projeto propõe uma infraestrutura simplificada para apoiar o
desenvolvimento e o estudo de um sistema de agendamento de consultas médicas.
O ambiente pode ser usado em atividades acadêmicas e adaptado conforme a
demanda, sem a pretensão de representar uma infraestrutura de produção pronta.

## Decisão

Adotar Linux como sistema operacional e VMware Workstation 17 como plataforma
para executar a máquina virtual. A configuração de referência da VM é:

- **Sistema operacional:** Ubuntu Server 26.04 LTS
- **Banco de dados:** MySQL 8.4.10
- **Servidor de aplicação:** Apache Tomcat

A VM e suas ferramentas servem como ambiente integrado para acesso,
manutenção e estudo. O repositório pode incluir os arquivos necessários para
configurar esse ambiente; configurações específicas podem variar conforme a
máquina, a rede e as atividades da disciplina.

### Credenciais e acesso

Credenciais não são documentadas neste repositório. Valores de demonstração
ou senhas iniciais não devem ser reutilizados nem publicados: configure
credenciais próprias fora do controle de versão e altere imediatamente qualquer
senha padrão antes de disponibilizar o ambiente.

O acesso remoto ao MySQL deve permanecer desabilitado por padrão. Se for
necessário para uma atividade, habilite-o apenas em uma rede confiável,
restrinja os endereços de origem e as portas no firewall e use contas com
permissões mínimas. Não exponha o serviço diretamente à Internet.

## Arquivos

- [`script.sql`](./script.sql): reservado para os comandos SQL do projeto.
  Atualmente está vazio; revise e teste os comandos em uma instância de
  desenvolvimento ou estudo antes de executá-los.

## Consequências

O ambiente oferece uma base reproduzível para estudar, manter e evoluir a
infraestrutura e facilita a migração para outro ambiente quando necessário.
Uma implantação real exige configuração própria de rede, segurança, backup,
monitoramento e credenciais; esses aspectos não são substituídos por esta
configuração didática.

## Autoria e referência acadêmica

O responsável informa que seu currículo está disponível na Plataforma Lattes,
em [lattes.cnpq.br](https://lattes.cnpq.br/), e autoriza seu uso para fins de
estudo, respeitados os direitos autorais. Para localizar o currículo, consulte
a plataforma e pesquise pelo nome do responsável.
