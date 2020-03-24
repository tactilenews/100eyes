<template>
  <v-layout>
    <v-flex class="text-center">
      <v-form v-model="valid">
        <v-text-field v-model="subject" label="Betreff" required></v-text-field>
        <v-textarea
          v-model="question"
          name="input-7-1"
          label="Frage an die Leser"
          hint="Gib eine Frage ein, welche eure Leser mit möglichst einem Wort beantworten können."
        ></v-textarea>
        <v-btn class="mr-4" @click="submit">Absenden</v-btn>
      </v-form>
    </v-flex>
  </v-layout>
</template>

<script>
export default {
  data() {
    return {
      valid: false,
      subject: '',
      question: ''
    }
  },
  methods: {
    submit() {
      const { subject, question } = this
      console.log(subject, question)
    }
  }
}
</script>
