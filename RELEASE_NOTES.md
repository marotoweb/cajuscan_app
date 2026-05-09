# 🚀 Novidades da Versão 1.0.6

### ✨ Novidades
- **Importação de Ficheiros:** Adicionada a capacidade de ler o QR Code em faturas diretamente de ficheiros PDF ou imagens da galeria, ideal para faturas recebidas por via digital.
- **Controlo de Fluxo de Scan:** O utilizador pode agora escolher nas Definições se deseja manter o scan contínuo (comportamento padrão anterior) ou se prefere regressar automaticamente à página inicial após cada leitura.
- **Interface Ergonómica:** Reestruturação da Página Inicial para posicionar os botões de ação na metade inferior do ecrã, facilitando o uso com apenas uma mão.

### 🛠️ Melhorias e Refatoração
- **Navegação Dinâmica:** O fluxo de saída do scanner foi refatorado para respeitar a preferência de scan selecionada pelo utilizador.
- **Tratamento de Erros:** Implementação de um atraso assíncrono e validações extra no scanner para evitar leituras duplicadas e aumentar a estabilidade em condições de pouca luz.

### 🔒 Segurança e Privacidade
- **Proteção de Logs:** Remoção total dos novos outputs de diagnóstico e logs de debug nas versões de produção.
- **Configurações Seguras:** A opção de "Confirmar no Cashew" está agora ativa por defeito, garantindo que os dados são validados pelo utilizador na submissão para o Cashew