## 1.0.8
# 🚀 Novidades da Versão 1.0.8

### ✨ Novidades
- **Motor de predição inteligente de contas:** A aplicação passa a sugerir automaticamente a conta de destino mais provável ao ler uma fatura. O algoritmo analisa o histórico local em dupla camada: primeiro tenta a conta mais frequente para aquele NIF e, se for um comerciante novo, recorre à conta mais utilizada globalmente, ordenando o menu de forma dinâmica.
- **Interface de confirmação redesenhada:** O ecrã de revisão de dados foi atualizado para uma navegação consistente baseada em cartões interativos. O toque no comerciante abre um diálogo de edição rápida do nome, enquanto a categoria e a conta abrem painéis inferiores integrados para uma seleção simples e limpa.
- **Pesquisa rápida de comerciantes:** Adicionada uma barra de pesquisa no topo da lista de comerciantes para encontrares instantaneamente qualquer estabelecimento por nome, NIF ou categoria.
- **Gestão de contas dedicada:** Nova secção nas definições para adicionar, editar ou remover as tuas contas de destino de forma simples e independente.
- **Importação de contas do Cashew:** Suporte expandido no *share sheet* para receber também a estrutura de contas de destino diretamente através da funcionalidade de partilha do Cashew.
- **Importação direta do Cashew:** Agora podes partilhar a estrutura de contas e categorias diretamente da funcionalidade de partilha do Cashew para a aplicação.
- **Exportações cronológicas:** O nome do ficheiro de backup passou a incluir um timestamp dinâmico gerado no momento da exportação (ex: `cajuscan-AAAA-MM-DD-HH-MM-SS.json`). Isto garante a ordenação cronológica natural dos ficheiros no sistema operativo e evita que backups antigos sejam sobrescritos por engano.

### 🛠️ Melhorias e Refatoração
- **Padronização do modelo Fatura:** Refatoração integral das propriedades da estrutura interna do modelo.
- **Navegação mais fluida:** Otimização interna da listagem de comerciantes para que a pesquisa e filtragem respondam de forma instantânea sem solavancos.
- **Segurança assíncrona:** Implementação de validações robustas com `context.mounted` em fluxos assíncronos de diálogos e alertas de eliminação.
- **Melhorias visuais:** Ajuste de ícones, introdução de setas indicadoras e menus mais claros nas definições.
- **Backup alargado:** O ficheiro de backup (`.json`) foi atualizado para salvaguardar de forma unificada os perfis de comerciantes, categorias, contas e todo o histórico de predição.

## 1.0.7
# 🚀 Novidades da Versão 1.0.7

### ✨ Novidades
- **Importar categorias do Cashew:** O CajuScan aparece agora no *share sheet* do Cashew, permitindo importar categorias directamente a partir da aplicação **Cashew -> Mais -> Configurações e personalização -> Importar e Exportar -> Exportar configuração -> Nomes das Categorias**
- **Importação manual:** Nova opção nas Definições para carregar uma exportação de categorias a partir de um ficheiro JSON ou TXT.
- **Confirmação antes de substituir:** Ao importar, é sempre apresentado um diálogo com o número de categorias encontradas antes de qualquer alteração.

## 1.0.6
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

## 1.0.5
# 🚀 Novidades da Versão 1.0.5  

### Corrigido
- **Codificação de URL:** Corrigido o erro onde as notas e títulos das transações exibiam carateres de codificação (como `%20` e `%0A`) no Cashew 6.4.4+. #5 #6

## 1.0.4
# 🚀 Novidades da Versão 1.0.4
Esta versão consolida a transição para uma arquitetura 100% Software Livre, corrigindo resíduos técnicos de bibliotecas proprietárias detetados em versões anteriores.

### 🛡️ Transição Concluída para Software Livre
- **Substituição do Google ML Kit**: Migração total do `mobile_scanner` (proprietário) para o **`flutter_zxing`**, uma solução puramente open-source para leitura de códigos de barras e QR.
- **Expurgo de Código Proprietário**: Limpeza profunda do binário para remover rastos do *Play Core SDK* que persistiam em cache, garantindo conformidade total com os padrões FOSS.

### ✨ Melhorias Técnicas e de Performance
- **Nova Interface de Scanner**: Integração otimizada do `ReaderWidget` com suporte a `CustomPainters` para manter a identidade visual e o overlay personalizado do CajuScan.
- **Otimização R8/Minify**: Ativação do motor de limpeza de código para garantir que apenas funções essenciais e livres sejam incluídas no APK final, resultando num binário mais leve e seguro.

### 📦 F-Droid & Privacidade
- **Conformidade FOSS Rigorosa**: Ajustes no motor de build (Gradle) para bloquear ativamente qualquer tentativa de injeção de dependências não-livres.
- **Privacidade Reforçada**: Garantia de que nenhum componente de telemetria ou serviços Google Play está presente no código.
- **Assinatura Oficial**: Binário assinado digitalmente pelo autor (**Roberto Cc**).
- **Build Determinístico**: Melhorias no pipeline de CI para reforçar a reprodutibilidade do binário.

## 1.0.3
# 🚀 Novidades da Versão 1.0.3
Esta versão marca um passo fundamental para a autonomia e transparência do projeto, garantindo total conformidade com os princípios de Software Livre (FOSS) e preparação para o F-Droid.

### 🛡️ Transição para Software Livre
- **Remoção do Google ML Kit**: Eliminada a dependência `mobile_scanner` que utilizava componentes proprietários da Google.
- **Implementação do Flutter ZXing**: Adicionado o `flutter_zxing (^2.2.1)`, uma solução totalmente open-source para leitura de códigos de barras e QR.

### ✨ Melhorias Técnicas
- **Nova Interface de Scanner**: Integração do `ReaderWidget` com callback `onScan` otimizado.
- **UI Preservada**: Manutenção da identidade visual através de `CustomPainters` personalizados para o overlay do scanner.

### 📦 F-Droid & Reproducible Builds
- **Assinatura Oficial**: APK assinado digitalmente pelo autor (Roberto Cc).
- **Build Reprodutível**: Configuração de build ajustada para permitir a verificação binária independente (RB).
- **Sem Ofuscação**: R8/ProGuard configurados para garantir que o binário corresponde exatamente ao código-fonte.

## 1.0.2
# 🚀 Novidades da Versão 1.0.2

- Substituído 'mobile_scanner' (dependente de Google ML Kit) por 'flutter_zxing'
- Removidas dependências proprietárias para garantir que o projeto seja 100% FOSS compativel com F-Droid
- Evolução da UI: Implementação de moldura e recorte com cantos côncavos 
- Otimização de performance com RepaintBoundary
- Correção de cintilação visual na animação da barra de scan
- Preparação para publicação do projeto no F-Droid

## 1.0.1
# 🚀 Novidades da Versão 1.0.1 (02-01-2026)

* **Compatibilidade Android 11+:** Adicionada configuração de visibilidade de pacotes (`<queries>`) para garantir que o Cashew seja detetado e aberto corretamente em versões modernas do Android. https://github.com/marotoweb/cajuscan_app/issues/1

**Full Changelog**: https://github.com/marotoweb/cajuscan_app/compare/v1.0.0...v1.0.1

## 1.0.0
# 🎉 Lançamento inicial do CajuScan! (v1.0.0)

É com grande entusiasmo que anunciamos a primeira versão pública do **CajuScan**, uma aplicação Android criada para simplificar e automatizar o registo das suas despesas em Portugal!

O objetivo desta aplicação é acabar com o processo manual de inserir os dados de uma fatura. Com o CajuScan, basta apontar a câmara para o QR Code e, em segundos, a sua despesa está pronta para ser registada na sua aplicação financeira preferida, o [Cashew](https://cashewapp.web.app/).

## ✨ Funcionalidades Principais Nesta Versão:

*   **Digitalização Rápida de QR Codes:** Leitura instantânea dos QR Codes de faturas portuguesas.
*   **Integração Direta com o Cashew:** Envia os dados da fatura (valor, data, NIF) para o Cashew, usando o método de registo direto (`/addTransaction`) ou o de confirmação (`/addTransactionRoute`), configurável nas definições.
*   **Gestão Inteligente de Comerciantes:** Guarde perfis de comerciantes associados a um NIF, com nome e categoria/subcategoria padrão, para automatizar futuros registos.
*   **Gestão Completa de Categorias:** Crie, edite, apague e restaure uma lista detalhada de categorias e subcategorias de despesa.
*   **Flexibilidade Total:**
    *   Adicione um comerciante à sua lista a partir de um QR Code sem criar uma transação.
    *   Adicione comerciantes manualmente na página de gestão.
    *   Edite os dados de uma fatura antes de a enviar para o Cashew.
*   **Backup e Restauro:** Exporte e importe todos os seus dados (perfis de comerciantes e categorias) para um ficheiro JSON, garantindo que nunca perde a sua configuração.

---

Este é apenas o começo! O futuro do CajuScan será moldado pelo feedback da comunidade. Se encontrar algum problema ou tiver sugestões, por favor, abra uma [Issue](https://github.com/marotoweb/cajuscan_app/issues).

Obrigado por experimentar o CajuScan!