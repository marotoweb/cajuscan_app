# 🚀 Novidades da Versão 1.0.6

### ✨ Novidades
- **Modo de Scan Contínuo:** Adicionada uma nova opção nas Definições que permite ler múltiplas faturas consecutivamente sem sair da câmara, maximizando a produtividade.
- **Interface Ergonómica:** Reestruturação da Página Inicial para posicionar os botões de ação na metade inferior do ecrã, facilitando o uso com apenas uma mão.

### 🛠️ Melhorias e Refatoração
- **Navegação Dinâmica:** O fluxo de saída do scanner agora adapta-se à preferência do utilizador (volta à Home no modo único ou permanece no scanner no modo contínuo).
- **Tratamento de Erros:** Adicionado um atraso assíncrono após falhas de leitura no QR Code para evitar processamento redundante e melhorar a estabilidade.

### 🔒 Segurança e Privacidade
- **Logs de Debug:** Proteção de logs, garantindo que informações de diagnóstico não são expostas em versões de produção.
- **Configurações Seguras:** A opção de "Confirmar no Cashew" passa a vir ativada por defeito para garantir que o utilizador valida sempre os dados na primeira utilização.
