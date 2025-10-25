# 🎉 Lançamento Inicial do CajuScan! (v1.0.0)

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
