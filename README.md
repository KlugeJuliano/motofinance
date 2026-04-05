# Review técnico do projeto MotoFinance

## Visão geral
O projeto tem uma boa base inicial (estrutura por `models/`, `providers/`, `repositories/`, `screens/` e testes), mas ainda está em estágio de protótipo. A camada de dados está parcialmente implementada (principalmente `JornadaRepository`), enquanto ganhos/despesas e parte da UI ainda usam placeholders e dados mockados.

## Pontos fortes
- Separação inicial por camadas (UI, estado, repositórios e banco local SQLite).
- `DatabaseHelper` já habilita foreign keys e define checks numéricos básicos para valores e quilometragem.
- Existem testes automatizados para banco/repositório, indicando preocupação com qualidade.

## Achados principais

### 1) Inconsistências de nomenclatura e modelo de dados (alto impacto)
- Classe `GahnoProvider` possui typo e mantém lista `_gahnos`.
- Modelo `Despesa` usa `jornalId` (provável typo de `jornadaId`).
- Mapeamento de `Ganho` usa chave `jornadaId`, enquanto no banco a coluna é `jornada_id`.

**Risco:** bugs silenciosos de serialização, dificuldade de manutenção e quebra na integração banco ↔ app.

### 2) Navegação com quantidade de abas inconsistente (alto impacto)
- O `DashboardPage` renderiza 4 telas no `IndexedStack`, mas exibe 5 itens no `BottomNavigationBar`.

**Risco:** erro de índice ao tocar na 5ª aba e crash em tempo de execução.

### 3) Repositórios de ganho/despesa não persistem dados (alto impacto)
- `GanhoRepository` e `DespesaRepository` são stubs com `Future.delayed` e retorno mock.
- Os providers correspondentes dependem desses métodos estáticos e não recebem `Database` por injeção.

**Risco:** funcionalidades parecem prontas na UI, mas sem persistência real.

### 4) Testes desatualizados em relação ao app atual (médio impacto)
- `test/widget_test.dart` ainda contém o teste padrão de contador do template Flutter, incompatível com a `MyApp` atual.
- Teste duplicado para foreign key em `database_helper_test.dart` (mesmo objetivo em dois casos).

**Risco:** falsa sensação de cobertura e testes frágeis.

### 5) UI com dados hardcoded e telas placeholders (médio impacto)
- Home usa valores fixos (km, ganhos, despesas, saldo).
- `GanhosPage` e `JornadaPage` ainda estão como `Placeholder`.

**Risco:** inconsistência entre protótipo visual e comportamento real esperado de produto.

## Recomendações priorizadas

### Prioridade 1 (estabilidade mínima)
1. Corrigir inconsistências de naming (`Gahno` → `Ganho`, `jornalId` → `jornadaId`) e alinhar mapeamento de colunas (`jornada_id` no banco/modelos).
2. Corrigir o número de páginas/itens na barra inferior para evitar `RangeError`.
3. Atualizar/remover o `widget_test` padrão e substituir por smoke tests reais das telas existentes.

### Prioridade 2 (funcionalidade real)
1. Implementar `GanhoRepository` e `DespesaRepository` com SQLite (CRUD real).
2. Injetar repositórios via `Provider` (evitar métodos estáticos) para facilitar testes e desacoplamento.
3. Conectar Home/Dashboard aos providers para eliminar dados hardcoded.

### Prioridade 3 (qualidade contínua)
1. Padronizar convenções (`snake_case` no banco, `camelCase` no Dart com mapeamento explícito).
2. Revisar cobertura de testes (repositórios + providers + navegação).
3. Configurar pipeline de CI com `flutter analyze` e `flutter test`.

## Comandos executados nesta review
- `flutter test` (não executou no ambiente: comando ausente).
- Leitura estática dos principais arquivos em `lib/`, `test/` e `README.md`.
