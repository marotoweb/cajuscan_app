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