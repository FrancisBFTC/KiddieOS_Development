# Contribuindo

* [Overview](#overview)
* [Como posso contribuir?](#contributing)
    - [Relatando bugs](#reporting-bugs)
    - [Sugestão de melhorias](#suggesting-improvements)
    - [Desenvolvimento](#developing)
    - [Tipos de colaboração](#collaboration)

<div id='overview'></div> 

## Overview

Obrigado por investir seu tempo em contribuir para o projeto.

Estas são as principais diretrizes, use seu bom senso e sinta-se à vontade para propor alterações a este documento em
um pull request.

<div id='contributing'></div> 

## Como posso contribuir?

Esta seção orienta você as possíveis maneiras de contribuir.

<div id='reporting-bugs'></div> 

### Relatando bugs

Os bugs são rastreados como [issues](https://github.com/backend-br/opensource-br/issues) no GitHub, crie um problema e
forneça as seguintes informações:

- Use um título claro e descritivo para identificar o problema.
- Descreva as etapas exatas que reproduzem o problema com o máximo de detalhes possível.

<div id='suggesting-improvements'></div> 

### Sugestão de melhorias

As sugestões de melhorias são rastreadas como [issues](https://github.com/FrancisBFTC/KiddieOS_Development/issues) no
GitHub, crie sua sugestão e forneça a informação a seguir:

- Use um título claro e descritivo para identificar a sugestão.
- Descreva o comportamento atual e explique qual comportamento você esperava ver e por quê.
- Explique porque esse aprimoramento seria útil para a maioria dos usuários.

<div id='developing'></div> 

### Desenvolvimento

Para iniciar o desenvolvimento, você precisará seguir alguns passos:

- Fork este repositório.
- Faça um clone do repositório que você fez seu fork.
- Crie uma branch a partir da branch `master`.
- Adicione sua contribuição, faça o commit e push.
- Abra um [pull request](https://github.com/FrancisBFTC/KiddieOS_Development/pulls).

<div id='collaboration'></div> 

### Tipos de colaboração

### Colaboração pro momento atual

- **Divulgação:** Como você mencionou, essa será um dos primeiros tipos, não tendo uma ordem específica de execução, mas que tem igual relevância. A divulgação será pra atrair mais colaboradores, interessados e usuários. Também vai servir pra aumentar nossa comunidade, que já é existente no Discord e no Youtube (KiddieOS.Community, posso te passar o link mais tarde se não tiver lá).  Você como divulgador, poderá até mesmo aumentar seu "Networking" e círculo de amizades de novos colaboradores, criar uma teia, uma rede de pessoas que te sigam e que até mesmo te "ajudem" a colaborar. É como se você fosse um professor alternativo do KiddieOS, que ajuda disseminar o conceito do KiddieOS nas redes sociais e grupos de programação.

- **Identificação de falhas:** Você pode ser um explorador de falhas no KiddieOS apenas em "tentar" utilizá-lo, e uma forma legal de se fazer isto é assistir o máximo de vídeos de "Demonstração" do KiddieOS no canal, que são vídeos que geralmente coloco **"KiddieOS:"** ou **"KiddieOS - "** no início do título, ou apenas um título **SEM** a tag #dsos, que é uma tag só relacionado para as "Video-aulas". Os vídeos de demonstração eu demonstro testes e novas funcionalidades desenvolvidas no KiddieOS, normalmente são vídeos mais curtos e sem voz (Com música de fundo). Assistindo estes vídeos, você aprende a como utilizar o KiddieOS existente e efetuar seus primeiros usos e testes, procurando bugs e reportando aqui em formato de **Issues** no Github, eu irei checar, corrigir em um tempo adequado e te dar um feedback didático do que ocasionou o bug e o que eu fiz pra corrigir, prezando também no seu próprio aprendizado sobre o sistema e sobre os desafios de programação (Detalhe: Não é necessário conhecer de programação pra explorar esses bugs, apenas usar e tentar fazer algo). Para criar Issues aqui, teria algumas regrinhas, mas nada tão exigente assim, apenas que detalhe bem nas descrições, crie um título do erro, e descreva o erro o melhor possível que você conseguir, pra me conseguir entender exatamente o que você estava tentando fazer e o que você esperava como resultado do seu teste, e assim saberei como corrigir ou terei uma forma melhor de procurar e corrigir o erro.

- **Sugestões de novos sistemas:** As sugestões são importantes, até pra filtrarmos os interesses e necessidades, e é algo frequentemente visto no meu canal, no entanto, uma sugestão jogada no ar na internet sem domínio técnico é apenas uma "Sugestão", correto? Algo que encontramos direto por aí. Okay, não é bem dessa forma que eu menciono esse tipo de sugestão que eu espero em uma dessas colaborações, vou explicar: Se você pede algo como - "Eu tenho uma sugestão: Crie um gerenciador de tarefas exatamente igual o do Windows" ou "Crie um driver de placa de vídeo avançada que rode qualquer jogo 3D do Windows", concorda que eu posso levar anos pra concluir estas coisas? E que são sugestões genéricas que todos pedem? Então, tente fugir desse tipo de sugestão. Eu gostaria de algo mais técnico, simples, objetivo e específico, quanto mais específico melhor e quanto mais enquadrado ao que já "existe" no sistema, melhor ainda. Por exemplo: Digamos que eu criei um novo comando pra checar "Detalhes" de arquivos, e aí nos seus testes, você identificou que seria bom ter um novo parâmetro para checar um detalhe específico de um tipo de arquivo.. e aí eu analisei a sua sugestão, estudei o caso e vi que realmente seria bom, então isso sim seria "Sugestão perfeita" digna de "Colaboração do KiddieOS". Isto significa que deve ser algo criteriosamente avaliado, validado e enquadrado nas necessidades atuais do sistema, medidas pelos seus estudos do KiddieOS e o que ele poderia ter "a mais" pra melhorar, algo que pode ser mais rápido de implementar mas que faria toda a diferença pra quem tivesse a mesma necessidade que você. Viu que não é algo apenas jogado no ar? Pode ser algo muito simples, um simples parâmetro de um comando, um simples ícone de uma janela, ou... um novo comando, talvez, uma nova rotina Assembly que complemente outra, existem milhares de sugestões boas que você poderá fazer.

### Colaboração pro momento futuro

- **Integração de Código:** Isso será feito utilizando a ferramenta de **Pull Request** do Github, no qual terá um documento escrito por mim citando as regras de utilização e envio (Todo repo mais completo tem algo assim). Integrar código seria você realizar o Fork do KiddieOS para seu próprio repo e máquina, e após o conhecimento avançado de toda a arquitetura estrutural e funcional do KiddieOS, você implementar seus próprios algoritmos para por exemplo: Novas Syscalls, novas interrupções de software, novas libraries, novas funções em libraries existentes, ou novos comandos do Shell, ou seja, você já tem uma base, já conhece Assembly e viu uma oportunidade de criar um código que funcione e testado por você. Você simplesmente enviaria uma solicitação de Pull (Pull Request) com suas novas modificações, juntamente com Imagens ScreenShots de Testes, descrições ricas de cada alteração, sua motivação em atribuir essa funcionalidade, etc... eu baixaria na minha máquina, testaria e se tivesse dentro dos padrões, sem afetar nenhuma outra funcionalidade e tendo um valor legal no sistema, eu concordaria com sua nova contribuição e realizaria o **Merge** da sua alteração com o Repo principal (Main) e sua nova funcionalidade estaria no KiddieOS. Essas novas funcionalidades poderiam ser desde simples/básicas até mais avançadas/maiores, no entanto, para esse tipo de Integração inicialmente, será preferencialmente recomendável pequenas alterações por motivos de segurança também, ou seja, funcionalidades menores. Isto é, preferível criar muitas funcionalidades menores uma de cada vez (pra cada Pull Request) como partes integrantes de um problema maior, do que todo o problema maior resolvido de uma vez só, na integração de código por Pull Request.

- **Otimização/Personalização:** Otimizar e personalizar pode sim ser criar algo novo, mas muito frequentemente ta ligado a mexer com algo que já ta pronto, por isso há uma alta taxa de riscos e uma grande probabilidade de reprovação no Pull Request, então exige maiores conhecimentos do que no tipo de colaboração anterior. Otimizar seria pegar um código que por natureza ta lento e aumentar sua eficiência, sua velocidade, trocando instruções, invertendo algoritmos ou refazendo partes do algoritmo sem afetar nenhuma outra funcionalidade pré-existente, deixando o algoritmo mais rápido, mais eficaz. Personalizar já é deixar algum sistema/algoritmo com características mais avançadas. Por exemplo: Se eu tenho uma janela gráfica do KiddieOS, que o padrão dela construída por mim foi: botão minimizar, maximizar, fechar, título da barra e só. Então você decide adicionar nas syscalls e interrupções de software uma nova personalização - adicionar menus com as mesmas funções dos botões no canto superior esquerdo da janela após um click de mouse, Opa, isso se trata de uma "personalização", é algo que foi acrescentado em outro existente pra tornar mais avançado e melhor a experiência do usuário. Mudar a cor da barra por exemplo seria considerado "Personalização"? Depende... se o KiddieOS já tiver uma função pra mudar a cor automaticamente da barra, neste caso não seria personalização, pois qualquer um poderia mudar, mas se ele não tiver essa função e você "Implementar" essa função pra alteração de cor dinâmica da barra por qualquer usuário, aí sim, é uma personalização. Mas apenas mudar a cor de X para Y não seria considerado personalização. E otimização? Okay, digamos que um algoritmo pra procurar a pasta X dentro de 50 pastas leve em torno de 1,3s (1 segundo e 300 milisegundos) na média ali segundo seus cálculos de eficiência e você encontrou uma forma algorítmica bem simples de alterar aquele algoritmo e que fez ele buscar a mesma pasta X nas 50 pastas por um tempo 50% inferior ao tempo original, como 650ms (650 milisegundos), isso é uma otimização. Poderia ser apenas 5% inferior, ou apenas 300 ms a menos de diferença, ainda é uma otimização, porque melhorou o algoritmo. No entanto, se essa diferença for insignificante demais, como apenas 5 ms, 10.. 50.. sei lá... algo que não faz diferença, já não seria uma otimização tão relevante. A otimização também pode ser enquadrada na correção de bugs, porque um sistema pode ter falhas, erros e defeitos, são 3 características diferentes... e você pode tanto que otimizar ou corrigir, tudo será uma otimização. Se você encontrar uma falha, mesmo que mínima, mas que pode acarretar lá na frente e souber corrigir, você ainda estará otimizando o sistema, então está valendo. Muitas vezes um defeito não é tão perceptível assim, erros e falhas é até mais fácil, mas deficiências, defeitos, é algo que só se descobre com o tempo de uso, como a velocidade de operação por exemplo e isso só pode ser corrigido via otimização.

- Agradeço por quem leu e compreendeu! Boas colaborações para vocês! :D 
