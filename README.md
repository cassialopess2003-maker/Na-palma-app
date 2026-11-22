# Na Palma — controle financeiro no iPhone

App iOS nativo (SwiftUI) para controlar suas finanças de forma simples, no visual padrão da Apple.

## O que o app faz

| Aba | Para que serve |
| --- | --- |
| **Início** | Saldo do mês, total de receitas e despesas, botões rápidos *Despesa* / *Receita*, contas que vencem nos próximos 7 dias, alertas de orçamento e últimos lançamentos. |
| **Extrato** | Todos os lançamentos do mês agrupados por dia, com busca, filtro (todos / despesas / receitas), edição com um toque e apagar deslizando. |
| **Gráficos** | Gráfico de rosca por categoria (despesas ou receitas) e barras comparando receitas × despesas dos últimos 6 meses. |
| **Planejar** | **Orçamentos** (limite mensal por categoria, com barra verde → laranja → vermelha), **Metas** (ex.: viagem, reserva de emergência) e **Contas fixas** (aluguel, salário, assinaturas). |
| **Ajustes** | Bloqueio com Face ID / Touch ID, ativação dos lembretes de contas, status do iCloud. |

Recursos:

- **Receitas e despesas** com 18 categorias com ícone e cor.
- **Lançamentos recorrentes**: cadastre uma vez e o app lança automaticamente todo mês.
- **Lembretes de contas**: notificação às 9h no dia do vencimento, 1 dia, 3 dias ou 1 semana antes.
- **iCloud**: os dados sincronizam entre seus aparelhos pela sua conta Apple (SwiftData + CloudKit). Sem iCloud, tudo fica salvo no iPhone.
- **Face ID**: o app bloqueia ao ir para segundo plano (usa o código do iPhone como alternativa).
- **Idioma e moeda seguem o iPhone**: português (Brasil) e inglês incluídos; a moeda vem da região do aparelho (R$ no Brasil).
- Modo claro/escuro automático e suporte a Dynamic Type.

## Requisitos

- Mac com **Xcode 16** ou mais recente
- iPhone com **iOS 17** ou mais recente

## Como rodar

1. Abra `NaPalma.xcodeproj` no Xcode.
2. Selecione o target **NaPalma** → aba **Signing & Capabilities**:
   - Em **Team**, escolha sua conta Apple (uma conta gratuita serve para testar no simulador).
   - Troque o **Bundle Identifier** `com.example.napalma` por um seu (ex.: `com.seunome.napalma`).
   - Em **iCloud**, troque o container `iCloud.com.example.napalma` por `iCloud.` + seu bundle id.
3. Escolha um simulador ou seu iPhone e aperte **⌘R**.

> Para sincronizar pelo iCloud em um iPhone de verdade é preciso uma conta paga do Apple Developer Program.
> Sem ela, remova a capability **iCloud** e **Push Notifications** em *Signing & Capabilities*: o app continua
> funcionando e salva tudo localmente.

## Estrutura

```
NaPalma/
├── App/            entrada do app, abas e banco de dados (SwiftData/iCloud)
├── Models/         FinanceEntry, EntryCategory, Budget, SavingsGoal, RecurringItem
├── Services/       formatação de moeda/datas, contas recorrentes, lembretes, Face ID
├── Views/          Início, Extrato, Gráficos, Planejar, Ajustes e componentes
├── Localizable.xcstrings   traduções (inglês → português)
└── Assets.xcassets         ícone e cor do app
Config/             Info.plist e entitlements (iCloud, notificações)
```
