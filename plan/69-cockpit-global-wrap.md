# 69 — Cockpit: global line-wrap toggle

## Contexto

Pedido do usuário: habilitar/desabilitar wrap para todas as janelas com um único botão. Posição confirmada: no header, imediatamente ao lado do ícone de informação (ⓘ).

## Estrutura esperada

- Um botão global no header existente; não repetir o controle em cada pane.
- Estado on/off compartilhado pelos panes relevantes, inclusive os novos e os que estão fora de foco.
- Aparência ativa/inativa, tooltip e semântica acessível que indiquem o estado e a ação.
- Reutilizar a infraestrutura de preferências existente para persistência.

## Passos com critério de aceite

1. Fotografar o header e os renderizadores de texto existentes em `cockpit/`. Verificar onde wrap já é suportado e registrar eventuais limites, especialmente nos terminais/TUIs. Se houver dúvida entre wrap de editor e wrap de terminal, confirmar o escopo antes de introduzir mudanças destrutivas.
2. Adicionar o botão junto ao ⓘ e conectar a uma única preferência global. Aceite: um clique altera todos os panes suportados imediatamente; novos panes herdam o estado.
3. Implementar wrap/no-wrap sem perder conteúdo. Não confundir preferência de apresentação com simplesmente desabilitar DEC autowrap e truncar/sobrescrever saída. Não reiniciar processos, limpar buffers ou alterar arquivos ao alternar.
4. Verificar alternância on/off com linhas longas em múltiplos panes, criação de novos panes, troca de foco e restauração da preferência. Cobrir o estado compartilhado e o botão com testes pertinentes; executar análise/testes somente dentro de `cockpit/`.

## Definition of Done

- [ ] Botão imediatamente ao lado do ⓘ no header.
- [ ] Um único estado compartilhado; panes novos herdam a escolha.
- [ ] Ambos os sentidos da alternância funcionam sem perda de conteúdo.
- [ ] Estado acessível e preferência persistente usando infraestrutura existente.
- [ ] Testes e análise reportados pelo agente do Cockpit.

## Próximos planos

Nenhum necessário. Implementação pertence a `cockpit/`; dispatch pendente porque esta sessão não tem acesso ao CLI interno/pane do Cockpit nem está conectada à mesh.
