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

## Versão web (sem Mac e sem login)

A pasta `web/` é um site completo que funciona como app no iPhone e no Android:
instala na tela inicial, funciona sem internet depois da primeira visita e guarda os dados no
próprio aparelho, com exportação e importação de backup em Ajustes.

Para colocar no ar de graça, arraste a pasta `web/` em https://app.netlify.com/drop
(ou use Cloudflare Pages / GitHub Pages). Não precisa de servidor nem de banco de dados.

## Jogo: Mercadinho (`web/mercadinho/`)

Um jogo casual de mercadinho em **3D estilo cartoon** (paleta Pastel Doce) (Three.js, incluído na pasta), **sem anúncios**, que roda no navegador do iPhone e do Android e pode ser
instalado na tela inicial (funciona sem internet depois da primeira visita).

- **Como jogar:** arraste o dedo em qualquer lugar da tela para andar (no computador, use WASD ou as setas).
- **Fazenda:** passe pelas plantações, galinheiro, curral e pomar para colher os produtos (eles vão para a sua pilha).
- **Loja:** encoste nas prateleiras para abastecê-las. Os clientes pegam o que querem e vão para a fila.
- **Caixa:** fique no quadrado ao lado do caixa para atender; depois pegue o dinheiro que fica no balcão.
- **Expandir:** pare em cima das placas verdes para comprar novas áreas (milho, ovos, leite, maçã, máquina de suco...).
- **Aberto / Fechado:** a placa no canto da tela abre e fecha o mercado. Fechado, não entram clientes novos
  (quem já está na loja termina as compras); a fazenda e os funcionários continuam trabalhando.
- **Personalizar (👕):** escolha pele, cabelo, chapéu, camisa e calça do seu personagem e de cada funcionário,
  com prévia em 3D, ou aplique o mesmo uniforme em toda a equipe.
- **Melhorias (🛠️):** mochila maior, tênis, adubo, prateleiras maiores, fama, preços premium,
  e contratar **caixa** e **repositores** que trabalham sozinhos.

O progresso fica salvo no próprio aparelho. Publicado junto com a pasta `web/`, o jogo fica em `…/mercadinho/`.
