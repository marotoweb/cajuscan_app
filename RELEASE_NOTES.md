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
