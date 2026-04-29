<script setup lang="ts">
import type { Message } from '../../api/sessions'
import { isSystemAction, isDeveloper, isArtifact } from './msg-utils'
import MsgSystem from './MsgSystem.vue'
import MsgFunction from './MsgFunction.vue'
import MsgDelegation from './MsgDelegation.vue'
import MsgDeveloper from './MsgDeveloper.vue'
import MsgArtifact from './MsgArtifact.vue'
import MsgText from './MsgText.vue'

defineProps<{ msg: Message }>()
</script>

<template>
  <MsgSystem v-if="isSystemAction(msg)" :msg="msg" />
  <MsgDeveloper v-else-if="isDeveloper(msg)" :msg="msg" />
  <MsgArtifact v-else-if="isArtifact(msg)" :msg="msg" />
  <MsgFunction v-else-if="msg.type === 'function'" :msg="msg" />
  <MsgDelegation v-else-if="msg.type === 'delegation'" :msg="msg" />
  <MsgText v-else :msg="msg" />
</template>
