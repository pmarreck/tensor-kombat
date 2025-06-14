# Tensor-Kombat

## A test to see if AI's can run a better debate than humans... Versus each other!

The project aims to explore the capabilities of AI in conducting debates against each other.

The user will be able to specify various AI's to battle it out- They will select 2 participant AI's and a scoring judge AI (it is OK if one AI has multiple roles). Initially, the following will be available:

1. ChatGPT 4 (latest)
2. Gemini Pro Experimental (latest)
3. Claude 4 (latest)
4. Grok (latest)
5. Various AI's enabled by Groq

The corresponding API keys are specified as ENV variables under the following names: ANTHROPIC_API_KEY, GOOGLE_GEMINI_API_KEY, OPENAI_API_KEY, GROK_API_KEY, GROQ_API_KEY

There is a hidden pre-prompt that is not user-editable which will brief the AI on the debate, its role in the debate (which side it's arguing for), how it will be judged when the debate is done (see below), and which will encourage the AI to "put on a good show"; the goal is informative entertainment. This might include strategies such as, using humor, sarcasm, or witty put-downs (making it personal) to set the other AI off, perhaps willingly engaging in known informative logical fallacies for entertainment value. This should not be overdone; think "spice", not "main ingredient".

The user will input a debate topic (example: "gun control"). The judge AI will be instructed to describe each side of the debate as an instruction to each participant (example: "Claude, you will be debating gun control with [ChatGPT/another instance of Claude]. You will be arguing for additional restrictions on gun ownership." (The judge AI will pick which AI to use to represent each side using a real random number generator provided by this program.)

A coin toss (done via the same real random number generator) will determine who goes first. Each participant in turn will receive the entire previous debate conversation and be instructed to respond to the last statement made by the other participant. The debate will go until both sides feel they have made their points. Sources ("grounding") is permitted if it can be done in realtime; all valid obtained sources will be cited in debate responses to buttress arguments.

The user will see each response as it comes in.

When both sides agree to end the debate, the judge AI will be instructed to score each party's participation in the debate on a 1-10 scale based on the following criteria:

1. Topic relevance
2. Quality of arguments
3. Use of sources
4. Overall coherence and flow; conciseness; clarity

The judge AI will now be asked to provide a final score for each participant (out of 100), a summary of the debate, and declare the winner.

The application will be designed using Hexagonal Design, with all core logic encapsulated in a pure function that is orthogonal to any particular interfaces, with complete separation of concerns.

An initial command-line interface in Bash will be created. Any markdown output will be rendered via `glow`.

A unit test interface will also be created for both the core logic/function, and the CLI.

Dependencies will be controlled via a flake.nix file; the core logic should use Idris 2.

Buildout should use TDD, taking small steps: 1) Write a failing unit test; 2) write the code to make it pass; 3) refactor as needed, 4) proceed to the next step.
