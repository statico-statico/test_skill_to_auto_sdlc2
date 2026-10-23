# **Diseño e Implementación de un GitHub Copilot Agent Skill para la Automatización del Ciclo SDLC: Integración con Rally MCP y GitLab**

## **1\. Evolución de los Agentes Autónomos en el Ecosistema de Desarrollo**

La intersección entre la inteligencia artificial generativa y la ingeniería de software ha superado la fase de asistencia reactiva para adentrarse en la era de los agentes autónomos integrados. Históricamente, las herramientas impulsadas por inteligencia artificial operaban en un entorno aislado, respondiendo a estímulos directos del desarrollador mediante la autocompletación de líneas de código o la refactorización de fragmentos específicos. La maduración de estas tecnologías ha permitido el desarrollo de modelos que operan en un nivel superior de abstracción, capaces de analizar repositorios completos, ejecutar comandos de terminal y orquestar flujos de trabajo complejos sin intervención humana continua1.  
El Modo Agente (Agent Mode) de GitHub Copilot, integrado nativamente en entornos como Visual Studio Code, representa una de las encarnaciones más sofisticadas de esta evolución técnica. A diferencia de Copilot Chat, que actúa como un asistente localizado respondiendo a preguntas inmediatas sobre archivos abiertos, el Modo Agente opera de forma autónoma dentro del entorno de desarrollo local1. Este modelo puede ejecutar ediciones en múltiples archivos, invocar comandos de terminal e iterar sobre errores de compilación mediante bucles de retroalimentación en tiempo real1. Este paradigma diverge de Copilot Workspace, el cual se enfoca en la planificación y ejecución a nivel de repositorio completo desde un entorno de nube efímero a partir de un *Issue* en GitHub, requiriendo un proceso secuencial de resumen de misión, plan de implementación, generación de código y creación de *Pull Request*1.  
Para arquitecturas corporativas que dependen de sistemas heterogéneos, como Broadcom Rally para la gestión del portafolio ágil y GitLab para el control de versiones, el Modo Agente de VS Code ofrece la arquitectura óptima. Proporciona la flexibilidad requerida para ejecutar herramientas de línea de comandos (CLI) locales, como glab, y acceder a protocolos de contexto personalizados que conectan herramientas externas, logrando una automatización que trasciende la simple generación de código. Al dotar a este agente con habilidades específicas (*Agent Skills*), se establece un conducto hiperautomatizado que gestiona el Ciclo de Vida del Desarrollo de Software (SDLC) completo, desde la concepción de una historia de usuario hasta la fusión del código3.

| Paradigma de Asistencia | Alcance Operativo | Persistencia y Contexto | Ejecución de Comandos | Caso de Uso Ideal |
| :---- | :---- | :---- | :---- | :---- |
| **Copilot Chat** | Localizado (archivo activo) | Efímero, basado en la ventana de chat. | Nula. Requiere intervención manual. | Explicación de código, generación de funciones individuales. |
| **Copilot Workspace** | Global (nube, repositorio) | Basado en *Issues* de GitHub, asincrónico. | Aislado en contenedores efímeros (Actions). | Refactorizaciones masivas multiplataforma desde un *Issue*. |
| **Copilot Agent Mode** | Local (entorno de desarrollo) | Continuo en la sesión del IDE local. | Control total del terminal local (con aprobación). | Automatización SDLC end-to-end integrando CLI y APIs locales. |

## **2\. Arquitectura de Integración: Model Context Protocol (MCP) en VS Code**

El éxito de una tubería (*pipeline*) SDLC hiperautomatizada depende críticamente de la interconexión de sistemas dispares mediante estándares universales. La arquitectura propuesta se fundamenta en el Model Context Protocol (MCP), un estándar abierto que proporciona una interfaz unificada para que los modelos de lenguaje interactúen bidireccionalmente con fuentes de datos y herramientas empresariales5. El despliegue de un servidor MCP en el ecosistema de VS Code dota al modelo subyacente de Copilot de capacidades de lectura y escritura directas sobre infraestructuras externas, como Broadcom Rally.

### **2.1 Configuración Topológica del Servidor MCP**

La arquitectura de MCP soporta diferentes mecanismos de transporte, siendo stdio (entrada/salida estándar) y HTTP/SSE (*Server-Sent Events*) los predominantes. En el contexto de VS Code, los servidores MCP locales se ejecutan generalmente a través de stdio, lanzando un proceso hijo que hereda la seguridad y el ciclo de vida de la sesión del entorno local, mientras que servidores remotos utilizan enlaces HTTP7.  
Para habilitar la integración con Rally, el agente requiere la declaración explícita del servidor en el entorno del desarrollador. La configuración de servidores MCP en VS Code utiliza el formato nativo almacenado en el archivo .vscode/mcp.json dentro del espacio de trabajo, o en el perfil de usuario global8. Este archivo JSON requiere una topología estricta dividida en objetos principales: servers para la definición de los procesos, inputs para la gestión segura de variables interactuables (como tokens de acceso), y opcionalmente sandbox para imponer restricciones de seguridad en sistemas UNIX8.  
Una configuración robusta para el conector de Rally MCP prohíbe terminantemente la codificación rígida (*hardcoding*) de credenciales en repositorios controlados por versión. En su lugar, el diseño arquitectónico debe inyectar el Token de Acceso Personal (PAT) de Rally mediante entradas seguras:

JSON  
{  
  "inputs": \[  
    {  
      "type": "promptString",  
      "id": "rally-pat",  
      "description": "Token de Acceso Personal (PAT) para Rally WSAPI",  
      "password": true  
    }  
  \],  
  "servers": {  
    "rally-mcp": {  
      "type": "stdio",  
      "command": "npx",  
      "args": \["@broadcom/rally-mcp-server"\],  
      "env": {  
        "RALLY\_API\_KEY": "\${input:rally-pat}"  
      }  
    }  
  }  
}

La inclusión de esta topología garantiza que el Agente en VS Code pueda descubrir dinámicamente herramientas encapsuladas por el servidor, como la herramienta FormattedID, diseñada específicamente para consultar y manipular historias de usuario y defectos en el entorno de Rally8. Alternativamente, infraestructuras más complejas pueden optar por el transporte HTTP apoyado en la autenticación OAuth, delegando la gestión del ciclo de vida del token directamente a la plataforma Broadcom8.

### **2.2 Sandboxing y Aislamiento de Procesos**

Otorgar a un modelo de lenguaje acceso a servidores MCP y terminales locales introduce vectores de riesgo significativos. Para mitigar escenarios donde una alucinación algorítmica resulte en operaciones destructivas sobre el sistema de archivos, VS Code implementa un mecanismo de *Sandboxing* para configuraciones stdio en sistemas macOS y Linux13.  
El bloque sandbox dentro de mcp.json permite definir reglas granulares sobre qué dominios de red pueden ser contactados y qué directorios específicos pueden recibir operaciones de escritura. Por ejemplo, se puede restringir al agente para que únicamente modifique archivos dentro del contexto definido por \${workspaceFolder}, bloqueando categóricamente el acceso de lectura a rutas críticas como \~/.ssh o variables de entorno del sistema8. Esta separación de privilegios es un prerrequisito innegociable cuando se orquestan despliegues automatizados desde el IDE.

## **3\. Estructura y Semántica de los Agent Skills (SKILL.md)**

Con la infraestructura subyacente operativa, el comportamiento autónomo del agente debe ser moldeado para seguir un flujo determinista. Esto se logra mediante la implementación de *Agent Skills* (Habilidades de Agente). A diferencia de las instrucciones globales del repositorio ubicadas en .github/copilot-instructions.md, un Skill es un módulo de conocimiento enfocado que codifica la experiencia en un dominio específico, integrando directrices metodológicas, políticas de calidad y secuencias de invocación de herramientas14.  
Un Skill reside en un directorio estructurado, típicamente .github/skills/nombre-de-habilidad/, y debe contener un archivo obligatorio denominado SKILL.md6. La anatomía de este archivo es bipartita, combinando un *frontmatter* en YAML para metadatos de enrutamiento y un cuerpo en Markdown para el procesamiento de lenguaje natural.

### **3.1 Especificación del Frontmatter YAML**

El orquestador de Copilot evalúa el *frontmatter* YAML para determinar el enrutamiento semántico, decidiendo en qué momento activar la habilidad durante una conversación con el usuario. Las especificaciones de los campos determinan cómo el modelo interactúa con el entorno antes de cargar las instrucciones completas16.

| Campo YAML | Restricciones de Especificación | Implicaciones Estructurales y Orquestación |
| :---- | :---- | :---- |
| name | Obligatorio. 1-64 caracteres, *kebab-case*, sin guiones consecutivos. | Actúa como el identificador único del Skill. Debe coincidir exactamente con el nombre del directorio padre16. |
| description | Obligatorio. 1-1024 caracteres. | Proporciona el contexto para el enrutamiento. Debe incluir palabras clave (ej. "Rally", "GitLab MR", "SDLC") para que el orquestador active el Skill autónomamente16. |
| allowed-tools | Opcional. Lista de strings. | Pre-aprueba el uso de herramientas específicas (ej. \#terminal, rally-mcp), reduciendo drásticamente las interrupciones por ventanas de confirmación de permisos durante la ejecución autónoma16. |
| metadata | Opcional. Pares clave-valor de cadenas. | Almacena propiedades adicionales como autoría o versión (version: "1.0"). Útil para auditorías de cumplimiento normativo16. |
| license / compatibility | Opcional. Cadenas de texto. | Define los requisitos ambientales (ej. dependencias de red o paquetes del sistema operativo necesarios para la ejecución)16. |

El campo allowed-tools asume una importancia crítica en la hiperautomatización. Al preautorizar el acceso a la herramienta rally-mcp y al \#terminal, el agente puede ejecutar el flujo SDLC continuo sin detenerse a solicitar aprobación humana en cada etapa, aplicando así el principio de automatización sin fricción mientras se mantiene el control de seguridad perimetral16.

### **3.2 Revelación Progresiva y Diseño del Cuerpo Instructivo**

El cuerpo del archivo SKILL.md dicta los procedimientos operativos estándar (SOP) divididos en fases lógicas. La calidad del resultado (output) emitido por el modelo de lenguaje depende absolutamente de la especificidad empírica de estas instrucciones14. Los modelos masivos de lenguaje (LLM), a pesar de su inmensa capacidad deductiva, son propensos a generar desviaciones arquitectónicas si no se imponen restricciones rígidas de validación paso a paso.  
El protocolo de *Agent Skills* utiliza una técnica de revelación progresiva para gestionar la ventana de contexto, la cual, aunque puede alcanzar teóricamente hasta 128,000 tokens en modelos como GPT-4o, está sujeta a límites prácticos de tasa de solicitudes (API Request Limits) impuestos por plataformas empresariales como GitHub Models (usualmente restringidos a 8,000 tokens de entrada por petición para asegurar el rendimiento)16.  
En la práctica, esto significa que el orquestador carga inicialmente solo el *frontmatter* (\~100 tokens) como índice. Solo cuando la consulta del usuario interactúa semánticamente con la description del Skill, se carga el cuerpo completo en Markdown (recomendado \< 5,000 tokens)15. Además, cualquier recurso suplementario (como plantillas de código, *scripts* bash en un directorio /scripts, o diagramas de referencia en /references) se inyecta en el contexto estrictamente a demanda, evitando la saturación de tokens y el consiguiente error HTTP 429 ("Too Many Requests")16.

## **4\. Orquestación del Ciclo SDLC (Fase 1): Ingesta de Contexto desde Broadcom Rally**

Con la estructura teórica definida, el agente inicia la ejecución del ciclo SDLC tras recibir un *prompt* desencadenante, tal como: *"Ejecuta la habilidad sdlc-rally-gitlab-automation para el requerimiento US10293"*.  
La fase primigenia obliga al agente a consultar la verdad fundamental del proyecto mediante el servidor Rally MCP. El protocolo de interacción subyacente se fundamenta en la API de Servicios Web (WSAPI) de Rally, una interfaz RESTful que maneja la estructura de datos mediante la sintaxis JSON23.

### **4.1 Extracción de Datos mediante WSAPI y FormattedID**

El agente invoca la herramienta MCP proporcionando el parámetro FormattedID correspondiente (ej. US10293). El servidor MCP traduce esta intención semántica en una consulta WSAPI, típicamente utilizando el parámetro query=(FormattedID \= "US10293") y el argumento fetch para restringir los campos devueltos25.  
La optimización de la consulta es fundamental en esta etapa. El agente está programado a través de su SKILL.md para evitar el uso de fetch=true, lo que provocaría la sobrecarga de la respuesta con atributos anidados masivos (campos de colección), impactando negativamente tanto en el rendimiento del servidor WSAPI como en la ingesta de tokens del LLM26. En su lugar, se instruye una búsqueda superficial (*Shallow Fetch*) centrada en campos críticos como Name, Description, ScheduleState, AcceptanceCriteria y Iteration26.

### **4.2 Transición de Estados (ScheduleState)**

Los objetos de tipo HierarchicalRequirement (Historias de Usuario) y Defect (Defectos) heredan la abstracción SchedulableArtifact, la cual contiene el campo inmutable y fundamental ScheduleState29. Este campo posee valores predefinidos que dictan el progreso en la iteración ágil: Defined, In-Progress, Completed, y Accepted31.  
El comportamiento del agente está estrictamente condicionado por este estado:

> 1. **Auditoría de Inmutabilidad:** Si el ScheduleState devuelto es Accepted, el agente debe abortar inmediatamente el flujo de trabajo. Alterar artefactos previamente aceptados por el dueño del producto viola las políticas de auditoría del ciclo de vida30.  
> 2. **Promoción de Estado:** Si el artefacto se encuentra en estado Defined, el agente emite una carga útil (*payload*) a la WSAPI a través del MCP para mutar el estado a In-Progress. Esta transición actualiza automáticamente el campo de solo lectura inProgressDate, alimentando en tiempo real las métricas del Flujo Acumulativo de la iteración y garantizando que las analíticas de velocidad del equipo permanezcan exactas sin que el desarrollador deba abandonar su IDE30.

## **5\. Orquestación del Ciclo SDLC (Fase 2): Modelado de Requerimientos y Diseño Arquitectónico**

La generación inmediata de código a partir de un simple ticket es un antipatrón en la ingeniería asistida por inteligencia artificial; suprime el análisis de sistemas y la planificación estructural, resultando frecuentemente en deuda técnica. Para contrarrestar esta deficiencia, el *Agent Skill* obliga al modo agente a materializar su entendimiento algorítmico en artefactos de texto plano ubicados en un directorio de documentación local (por ejemplo, .docs/).

### **5.1 Síntesis de requerimientos.md**

El agente procesa el contenido extraído de los campos Description y AcceptanceCriteria de Rally. A continuación, mediante el uso integrado de la herramienta de manipulación de archivos local (una capacidad inherente al Modo Agente de VS Code que no depende de MCP), el agente genera el archivo requerimientos.md33.  
Este documento no es una mera transcripción; el LLM es instruido para reestructurar la prosa ambigua en objetivos verificables y atómicos. El proceso exige que el agente razone explícitamente sobre casos límite, precondiciones de fallo y restricciones de seguridad, alineando los requisitos de negocio con las prácticas del Desarrollo Guiado por Comportamiento (BDD)14.

### **5.2 Formulación de diseño.md**

Simultáneamente, el agente interroga el estado actual del proyecto mediante la herramienta \#codebase. Esta capacidad permite al modelo indagar en la arquitectura existente, revisando convenciones de nomenclatura, esquemas de inyección de dependencias y patrones de diseño predominantes en el repositorio14.  
Basándose en este análisis semántico, se genera el archivo diseño.md. El documento debe contener:

* Un mapeo preciso de los archivos que sufrirán modificaciones.  
* Las nuevas interfaces, contratos de datos (Data Transfer Objects) o dependencias de paquetes (ej., NuGet o NPM) que serán introducidos.  
* El diseño de los vectores de prueba requeridos para satisfacer los criterios documentados en el paso anterior4.

Esta fase emula procedimentalmente la etapa del "Plan de Vuelo" característica de Copilot Workspace, pero con la ventaja estratégica de ejecutarse dentro del bucle local, permitiendo al desarrollador intervenir, revisar los documentos .md y proporcionar rectificaciones menores en el chat antes de autorizar la alteración del código fuente1.

## **6\. Orquestación del Ciclo SDLC (Fase 3): Implementación Autónoma, Pruebas e Iteración**

Una vez que el plano arquitectónico ha sido consolidado en el contexto local, el Agente transita hacia la fase de implementación de código, aprovechando las capacidades simbióticas de la comprensión del \#codebase y la ejecución del \#terminal14.

### **6.1 Escritura de Código y Subhabilidades (Subskills)**

El Agente elabora los fragmentos funcionales y los inscribe directamente en el sistema de archivos local33. Para asegurar que el código no degrade la base existente, la arquitectura del *Skill* principal puede referenciar subhabilidades modulares. Por ejemplo, se pueden cargar las políticas de security-audit (para prevenir vulnerabilidades comunes como inyecciones SQL) o logging-check (para estandarizar las trazas del sistema) definidas en otros archivos SKILL.md dentro del mismo ecosistema14.  
Cada archivo modificado debe estar documentado con comentarios internos que referencien el identificador FormattedID de Rally, asegurando la trazabilidad de granularidad fina a nivel de línea de código.

### **6.2 Ejecución de Pruebas y Ciclo de Auto-Sanación (Self-Healing)**

La automatización SDLC carece de validez si no incorpora la verificación de la calidad. El modo agente, dotado de autonomía mediante la herramienta \#terminal, es instruido para disparar la suite de pruebas unitarias y de integración del proyecto local (por ejemplo, dotnet test, npm run test, o pytest)2.  
Si la ejecución de la prueba resulta en un estado fallido, el agente despliega su capacidad de "auto-sanación" (*self-healing*). Lee interactivamente el volcado del registro de errores (*stack trace*) desde la salida estándar del terminal, contextualiza el fallo frente a su diseño.md original, aplica la corrección sobre los archivos pertinentes e itera el comando de prueba2. Este bucle cerrado persiste de manera determinista hasta que el terminal reporta un estado exitoso (color verde), momento en el cual el agente solicita la autorización para avanzar hacia las operaciones de integración de control de versiones1.

## **7\. Orquestación del Ciclo SDLC (Fase 4): Control de Versiones y Merge Requests mediante GitLab CLI (glab)**

Completada la validación algorítmica local, el ciclo de vida avanza hacia la gestión de repositorios remotos. Para mantener la hiperautomatización y eliminar la fricción de la interfaz gráfica, el agente es instruido para orquestar Git y GitLab utilizando exclusivamente el terminal local36.  
La infraestructura del desarrollador debe contar con el binario de la CLI de GitLab (glab) previamente autenticado (glab auth login), poseyendo un token con privilegios adecuados para bifurcar, empujar código y crear discusiones37.

### **7.1 Secuencia Imperativa de Git**

El *Agent Skill* dicta una rigurosa secuencia de comandos de control de versiones ejecutados vía \#terminal:

> 1. git checkout \-b feature/US10293-implementacion-modulo: Se crea una rama efímera cuyo identificador incorpora la taxonomía de Rally, asegurando un vínculo explícito en el árbol de Git.  
> 2. git add . seguido de git commit \-m "feat(US10293): implementa requerimientos según diseño \[cite: 38\]": Se realiza un compromiso atómico que respeta las convenciones estandarizadas de la industria.  
> 3. git push \-u origin HEAD: El código se sincroniza de forma segura con el repositorio remoto39.

### **7.2 Creación Automatizada del Merge Request (glab mr create)**

La fase culminante del control de versiones es la generación del Merge Request. Para que un agente autónomo complete esta tarea exitosamente, el comando glab mr create debe estructurarse con banderas (*flags*) específicas que supriman cualquier ventana de interacción humana (la cual pausaría indefinidamente el progreso del agente)36.  
El comando paramétrico óptimo ejecutado por la IA se diseña de la siguiente manera:

Bash  
glab mr create \--fill \--yes \--draft \--assignee @me \--label "bot-generated,US10293" \--description-file .docs/report.md

| Parámetro glab mr create | Función Mecánica | Implicación en Automatización |
| :---- | :---- | :---- |
| \--fill | Fusiona la información del historial de commits recientes. | Elimina la necesidad de pasar el título explícitamente y asegura que el progreso semántico del código se refleje en el MR, además de forzar un push automático si no se desactiva36. |
| \--yes | Omite el aviso de confirmación de envío. | **Crítico**. Sin esta bandera, la CLI se pausaría solicitando la confirmación de la entrada estándar (stdin), rompiendo la cadena de automatización del agente36. |
| \--draft | Marca el MR como borrador o trabajo en progreso. | Evita que las tuberías CI/CD remotas realicen despliegues prematuros antes de la revisión final humana36. |
| \--assignee @me | Asigna el MR al usuario autenticado. | Fomenta la responsabilidad directa del desarrollador que invocó al agente36. |

Un factor decisivo en la arquitectura del comando es la generación del cuerpo del MR. Aunque GitLab soporta la inyección automática de plantillas predefinidas ubicadas en rutas específicas del repositorio local como .gitlab/merge\_request\_templates/default.md mediante la bandera \--template41, la naturaleza dinámica del *Agent Skill* favorece el uso de la bandera \--description-file36.  
Esta directriz instruye a la CLI a leer el contenido de un archivo local generado *ad-hoc* por el agente (por ejemplo, el inminente report.md) inyectando directamente en el MR un resumen detallado de los riesgos mitigados, los patrones arquitectónicos empleados y las pruebas ejecutadas, proporcionando a los revisores humanos un contexto inigualable sin esfuerzo adicional36. (Se debe evitar la bandera \--attach para incluir capturas o archivos binarios en automatizaciones críticas, ya que la documentación oficial la cataloga actualmente como experimental y sujeta a inestabilidad)36.

## **8\. Orquestación del Ciclo SDLC (Fase 5): Cierre de Trazabilidad y Actualización Bidireccional en Rally**

La creación del Merge Request produce una URL y un identificador interno en el ecosistema de GitLab. El agente, monitoreando la salida estándar del comando previo, debe extraer este identificador para iniciar la fase de convergencia y actualizar la plataforma de gestión del portafolio.

### **8.1 Finalización del Estado en Rally**

Utilizando nuevamente el conector Rally MCP, el agente envía un *payload* de actualización a la WSAPI para el artefacto identificado. El ScheduleState debe avanzar obligatoriamente de In-Progress a Completed31. Esta transición semántica comunica a las métricas del equipo Ágil (como los *burndown charts*) que la codificación técnica ha concluido satisfactoriamente y que el requerimiento se encuentra a la espera de la revisión final y aprobación formal del dueño del producto (quien establecerá el estado definitivo de Accepted)30.

### **8.2 Anclaje de Discusiones y Comentarios de Referencia Cruzada**

Una automatización deficiente crea silos de información; una hiperautomatización los elimina mediante referencias cruzadas. El agente está programado para aprovechar las capacidades de discusión de ambas plataformas:

> 1. **Comentario en Rally WSAPI:** A través de los servicios REST JSON de Rally enfocados en la API de Discusión, el agente adjunta un comentario inmutable al HierarchicalRequirement: *"La implementación técnica ha sido completada por el Agente Copilot. Enlace al Merge Request: \[URL\_GITLAB\]."*. Esto garantiza que los gestores de proyecto puedan rastrear el progreso desde su interfaz sin necesidad de navegar al repositorio de código24.  
> 2. **Generación de Nota en GitLab MR (glab mr note create):** Simultáneamente, el agente utiliza la CLI de GitLab para anclar información técnica en el MR recién creado. Utilizando el comando glab mr note create \-m "Validación algorítmica completada: Análisis de cobertura estático aprobado. Pendiente revisión humana.", el agente inicializa un nuevo hilo de discusión45. Es imperativo instruir al agente para que utilice esta sintaxis moderna; el uso exclusivo de glab mr note create inicia hilos resolubles, superando los métodos heredados o *scripts* personalizados mediante cURL que carecían de integración nativa con los estados de resolución de hilos requeridos para la fusión en repositorios estrictos45.

## **9\. Gobernanza, Documentación de Cierre (report.md) y Gestión de Riesgos**

La transferencia final de responsabilidad del agente autónomo al ingeniero humano se materializa a través de un documento de síntesis. El *Agent Skill* obliga a la generación de un archivo report.md post-tarea en el directorio local .docs/. Este reporte, el cual es inyectado previamente en el cuerpo del Merge Request mediante \--description-file, es el pilar de la gobernanza de IA.

### **9.1 Anatomía del report.md Post-Tarea**

El archivo consolida la memoria de la sesión efímera del agente. Su estructura debe clasificar explícitamente:

* **Trazabilidad del Desarrollo:** Un inventario tabular de los archivos modificados y su justificación funcional derivada del diseño.md.  
* **Alineación con Mejores Prácticas:** Declaraciones sobre cómo el código producido adhiere a los principios SOLID y si se implementaron patrones de diseño modernos.  
* **Evaluación de Seguridad (OWASP):** Un análisis resumen generado por el LLM respecto a los vectores de riesgo abordados. Por ejemplo, asegurar que cualquier entrada de datos introducida en esta iteración esté sujeta a desinfección paramétrica para mitigar vulnerabilidades de inyección, o validar que la gestión de estado evada vulnerabilidades criptográficas prevalentes en el *OWASP Top 10*14.

### **9.2 Gestión Sistemática de Riesgos de IA**

El diseño e implementación de este nivel de automatización expone a la organización a vulnerabilidades tecnológicas si no se administran adecuadamente.  
**Agotamiento de Cuotas y Límites de Frecuencia (Rate Limiting):** Las llamadas constantes al Rally MCP, las consultas subyacentes de GitHub Copilot hacia sus propios servicios LLM y los *fetches* del GitLab CLI consumen una alta densidad de peticiones de red. Los sistemas limitadores frecuentemente devuelven errores HTTP 429 ("Too Many Requests") fundamentados en cuotas operativas tipo UserByModelByDay o límites de "Tokens por Minuto" (TPM)21. Si el agente satura estos límites (por ejemplo, forzando un modelo complejo como gpt-4o a leer iterativamente un log de terminal masivo de 50,000 líneas), la sesión fracasará corruptamente21. La configuración robusta del Skill debe exigir el uso de retroceso exponencial (*Exponential Backoff*) en herramientas personalizadas, promoviendo pausas cuando se detecten umbrales de advertencia en las respuestas de la API22.  
**Confinamiento de Ejecución y *Sandboxing*:** La delegación de la terminal a un agente autónomo posee ramificaciones existenciales para el entorno de desarrollo. En VS Code, aunque la instancia de conexión stdio herede la "Confianza del Espacio de Trabajo" (Workspace Trust) validada por el usuario13, se deben aplicar políticas rigurosas. La arquitectura debe forzar la revisión humana asincrónica de todo el código (razón subyacente para el uso irrenunciable del flag \--draft en la creación del MR)2. Adicionalmente, se recomienda que, en infraestructuras compatibles con macOS/Linux, el bloque sandbox del mcp.json configure denyRead para directorios sensibles del sistema fuera de \${workspaceFolder}8.  
En conclusión, la estructuración hiperautomatizada del SDLC a través de un GitHub Copilot Agent Skill transforma radicalmente la productividad de la ingeniería. Al acoplar el Model Context Protocol para gobernar las interfaces de Broadcom Rally, instrumentar restricciones YAML deterministas, y desplegar la CLI de GitLab para el control de la integración, la organización traslada el foco de sus ingenieros desde la gestión transaccional burocrática hacia la revisión estratégica de soluciones impulsadas algorítmicamente.

#### **Obras citadas**

> 1. GitHub Copilot Workspace Reviewed for Issue-to-PR Workflows, [https\://blog.vibecoder.me/github-copilot-workspace-hands-on-review](https://blog.vibecoder.me/github-copilot-workspace-hands-on-review)  
> 2. The difference between coding agent and agent mode in GitHub, [https\://github.blog/developer-skills/github/less-todo-more-done-the-difference-between-coding-agent-and-agent-mode-in-github-copilot/](https://github.blog/developer-skills/github/less-todo-more-done-the-difference-between-coding-agent-and-agent-mode-in-github-copilot/)  
> 3. 2026 GitHub Copilot Agent Mode Review: VS Code AI Agent \- AI 織夢, [https\://weavai.app/blog/en/2026/05/12/2026-github-copilot-agent-mode-review-vs-code-ai-agent/](https://weavai.app/blog/en/2026/05/12/2026-github-copilot-agent-mode-review-vs-code-ai-agent/)  
> 4. Agent Skills Example \- GitHub Copilot Visual Studio 2026, [https\://dev.to/incomplete\_developer/agent-skills-example-github-copilot-visual-studio-2026-4jik](https://dev.to/incomplete_developer/agent-skills-example-github-copilot-visual-studio-2026-4jik)  
> 5. Model Context Protocol: An essential standard for AI-powered tool, [https\://retool.com/blog/what-is-model-context-protocol](https://retool.com/blog/what-is-model-context-protocol)  
> 6. Use Agent Skills in VS Code, [https\://code.visualstudio.com/docs/agent-customization/agent-skills](https://code.visualstudio.com/docs/agent-customization/agent-skills)  
> 7. Adding an MCP Server to a VS Code Extension \- Ken Muse, [https\://www\.kenmuse.com/blog/adding-mcp-server-to-vs-code-extension/](https://www.kenmuse.com/blog/adding-mcp-server-to-vs-code-extension/)  
> 8. MCP configuration reference \- Visual Studio Code, [https\://code.visualstudio.com/docs/agents/reference/mcp-configuration](https://code.visualstudio.com/docs/agents/reference/mcp-configuration)  
> 9. VS Code MCP Setup Guide: mcp.json and Servers \- datamcp, [https\://datamcp.app/blog/vscode-mcp-setup-guide](https://datamcp.app/blog/vscode-mcp-setup-guide)  
> 10. Supercharge GitHub Development with mcp.json in Visual Studio, [https\://medium.com/@praveen.valaboju1/supercharge-github-development-with-mcp-json-in-visual-studio-code-37675fcdf272](https://medium.com/@praveen.valaboju1/supercharge-github-development-with-mcp-json-in-visual-studio-code-37675fcdf272)  
> 11. Tools \- What is the Model Context Protocol (MCP)?, [https\://modelcontextprotocol.io/specification/2025-06-18/server/tools](https://modelcontextprotocol.io/specification/2025-06-18/server/tools)  
> 12. Rally MCP \- Rally Help Center, [https\://help.rallyuxr.com/articles/5139669410-rally-mcp](https://help.rallyuxr.com/articles/5139669410-rally-mcp)  
> 13. Manage and troubleshoot MCP servers \- Visual Studio Code, [https\://code.visualstudio.com/docs/agents/run/manage-mcp-servers](https://code.visualstudio.com/docs/agents/run/manage-mcp-servers)  
> 14. Building VS Code Agents with Skills & Tools \- Medium, [https\://medium.com/@krish777/building-vs-code-agents-with-skills-tools-e682e69b45c9](https://medium.com/@krish777/building-vs-code-agents-with-skills-tools-e682e69b45c9)  
> 15. AGENTS.md and SKILL.md examples: build a reusable agent toolbox, [https\://chrisreddington.com/blog/building-your-agent-toolbox/](https://chrisreddington.com/blog/building-your-agent-toolbox/)  
> 16. Specification \- Agent Skills, [https\://agentskills.io/specification](https://agentskills.io/specification)  
> 17. Creating Skills for Copilot Studio Agents: How to use the SKILL.md, [https\://holgerimbery.blog/creating-skills-copilot-studio-agents](https://holgerimbery.blog/creating-skills-copilot-studio-agents)  
> 18. SKILL.md frontmatter validation rejects unknown attributes \- GitHub, [https\://github.com/microsoft/vscode/issues/294520](https://github.com/microsoft/vscode/issues/294520)  
> 19. Adding agent skills for GitHub Copilot, [https\://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)  
> 20. GitHub Copilot GPT-4o API Pricing Calculator \- TypingMind Teams, [https\://custom.typingmind.com/tools/estimate-llm-usage-costs/github-copilot/gpt-4o](https://custom.typingmind.com/tools/estimate-llm-usage-costs/github-copilot/gpt-4o)  
> 21. Rate Limits and File Uploads in GitHub Models \#149698, [https\://github.com/orgs/community/discussions/149698](https://github.com/orgs/community/discussions/149698)  
> 22. Mastering GitHub Models API: Rate Limits, Quotas, and Software, [https\://dev.to/devactivity/mastering-github-models-api-rate-limits-quotas-and-software-engineering-quality-4fk1](https://dev.to/devactivity/mastering-github-models-api-rate-limits-quotas-and-software-engineering-quality-4fk1)  
> 23. Rally Web Services API \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api.html)  
> 24. REST JSON Services \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api/rest-services-overview/rest-json-services.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api/rest-services-overview/rest-json-services.html)  
> 25. Rally API docs, [https\://api-docs.rallyon.com/](https://api-docs.rallyon.com/)  
> 26. Rally \- WSAPI \- Best Practices on filtering and queries., [https\://knowledge.broadcom.com/external/article/125586/rally-wsapi-best-practices-on-filterin.html](https://knowledge.broadcom.com/external/article/125586/rally-wsapi-best-practices-on-filterin.html)  
> 27. README.md \- Cox-Automotive/rally-wsapi \- GitHub, [https\://github.com/Cox-Automotive/rally-wsapi/blob/master/README.md](https://github.com/Cox-Automotive/rally-wsapi/blob/master/README.md)  
> 28. Fetch user stories by iteration using Rally API \- Stack Overflow, [https\://stackoverflow.com/questions/23738819/fetch-user-stories-by-iteration-using-rally-api](https://stackoverflow.com/questions/23738819/fetch-user-stories-by-iteration-using-rally-api)  
> 29. Examples of queries by ScheduleState \- Broadcom support portal, [https\://knowledge.broadcom.com/external/article/57599/examples-of-queries-by-schedulestate.html](https://knowledge.broadcom.com/external/article/57599/examples-of-queries-by-schedulestate.html)  
> 30. API Versioning \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api/api-versioning.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/reference/rally-web-services-api/api-versioning.html)  
> 31. Modifying Schedule States \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/administration/managing-your-workspace/modifying-schedule-states.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/administration/managing-your-workspace/modifying-schedule-states.html)  
> 32. Rally web service API: get Hierarchical Requirements from a specific, [https\://stackoverflow.com/questions/12297486/rally-web-service-api-get-hierarchical-requirements-from-a-specific-day-in-an-i](https://stackoverflow.com/questions/12297486/rally-web-service-api-get-hierarchical-requirements-from-a-specific-day-in-an-i)  
> 33. Choosing Between GitHub Copilot CLI and VS Code Agent Mode for, [https\://zenn.dev/tomokusaba/articles/838cdac8d71e52?locale=en](https://zenn.dev/tomokusaba/articles/838cdac8d71e52?locale=en)  
> 34. What is MCP and How to Use It in VS Code (With a Simple Example), [https\://dev.to/hamidrazadev/what-is-mcp-and-how-to-use-it-in-vs-code-with-a-simple-example-3mda](https://dev.to/hamidrazadev/what-is-mcp-and-how-to-use-it-in-vs-code-with-a-simple-example-3mda)  
> 35. Visual Studio March Update \- Build Your Own Custom Agents, [https\://devblogs.microsoft.com/visualstudio/visual-studio-march-update-build-your-own-custom-agents/](https://devblogs.microsoft.com/visualstudio/visual-studio-march-update-build-your-own-custom-agents/)  
> 36. glab-mr-create(1) \- Arch Linux manual pages, [https\://man.archlinux.org/man/glab-mr-create.1.en](https://man.archlinux.org/man/glab-mr-create.1.en)  
> 37. glab mr create does not have a \--template option (\#7924) \- cli \- GitLab, [https\://gitlab.com/gitlab-org/cli/-/issues/7924](https://gitlab.com/gitlab-org/cli/-/issues/7924)  
> 38. Scaling My Engineering Workflow with Github Copilot Agents, [https\://dev.to/ivolondon/the-rise-of-the-fleet-scaling-my-engineering-workflow-with-vscode-copilot-agents-3boe](https://dev.to/ivolondon/the-rise-of-the-fleet-scaling-my-engineering-workflow-with-vscode-copilot-agents-3boe)  
> 39. How to create a GitLab merge request via command line, [https\://stackoverflow.com/questions/37410262/how-to-create-a-gitlab-merge-request-via-command-line](https://stackoverflow.com/questions/37410262/how-to-create-a-gitlab-merge-request-via-command-line)  
> 40. glab-mr-create man \- Linux Command Library, [https\://linuxcommandlibrary.com/man/glab-mr-create](https://linuxcommandlibrary.com/man/glab-mr-create)  
> 41. glab mr create \- GitLab Docs, [https\://docs.gitlab.com/cli/mr/create/](https://docs.gitlab.com/cli/mr/create/)  
> 42. glab-mr-create: Create a new merge request. \| Man Page \- ManKier, [https\://www\.mankier.com/1/glab-mr-create](https://www.mankier.com/1/glab-mr-create)  
> 43. Use Discussions \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/using-rally/common-pages-and-elements/detail-editor/using-the-detail-editor/use-discussions.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/using-rally/common-pages-and-elements/detail-editor/using-the-detail-editor/use-discussions.html)  
> 44. Discussions \- Broadcom TechDocs, [https\://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/using-rally/common-tasks/collaborate-with-team-members/discussions.html](https://techdocs.broadcom.com/us/en/ca-enterprise-software/valueops/rally/rally-help/using-rally/common-tasks/collaborate-with-team-members/discussions.html)  
> 45. glab mr note create \- GitLab Docs, [https\://docs.gitlab.com/cli/mr/note/create/](https://docs.gitlab.com/cli/mr/note/create/)  
> 46. glab mr \| Skills Marketplace \- LobeHub, [https\://lobehub.com/skills/vince-winkintel-gitlab-cli-skills-glab-mr](https://lobehub.com/skills/vince-winkintel-gitlab-cli-skills-glab-mr)  
> 47. glab mr note create adds discussion-based notes \- sincecutoff.com, [https\://sincecutoff.com/c/glab-mr-note-create-adds-discussion-based-notes-7d347adf6fe2/](https://sincecutoff.com/c/glab-mr-note-create-adds-discussion-based-notes-7d347adf6fe2/)  
> 48. GitHub Models: Free GPT, Llama, Phi Models & API \- IT 空間, [https\://blog.jiatool.com/en/posts/github\_models/](https://blog.jiatool.com/en/posts/github_models/)  
> 49. Support for secondary and additional rate limits · Issue \#2113 \- GitHub, [https\://github.com/PyGithub/PyGithub/issues/2113](https://github.com/PyGithub/PyGithub/issues/2113)  
> 50. Using Retry in HTTP Requests with Python \| by Hudson Brendon, [https\://medium.com/@hudsonbrendon/using-retry-in-http-requests-with-python-5c46e3280893](https://medium.com/@hudsonbrendon/using-retry-in-http-requests-with-python-5c46e3280893)