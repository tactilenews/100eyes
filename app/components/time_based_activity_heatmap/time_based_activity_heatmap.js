import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['heatmap'];

  connect() {
    this.fetchTimeBasedActivityData();
    console.log('connected', this.heatmapTarget);
  }

  async fetchTimeBasedActivityData() {
    const response = await fetch('charts/time-based-activity');
    const jsonResponse = await response.json();
    const options = this.setUpChart(jsonResponse);
    this.renderChart(options);
  }

  setUpChart(jsonResponse) {
    let series = ["Sonntag", "Samstag", "Freitag", "Donnerstag", "Mittwoch", "Dienstag", "Montag"].map(day => ({ name: day, data: [] }))
    for (const [key, value] of Object.entries(jsonResponse)) {
        series.forEach(object => {
        if (JSON.parse(key)[0] == object.name) {
            console.log('hour', )
          object.data.push({ x: JSON.parse(key)[1], y: value });
        }
      })
    }

    return {
      chart: {
        type: 'heatmap'
      },
      series: series,
      plotOptions: {
        heatmap: {
          colorScale: {
            ranges: [{
                from: 0,
                to: 5,
                color: '#F8C8DC',
                name: 'Keine oder wenig',
              },
              {
                from: 6,
                to: 20,
                color: '#FFB6C1',
                name: 'Leicht',
              },
              {
                from: 21,
                to: 45,
                color: '#FF00A0',
                name: 'Mittel',
              },
              {
                from: 46,
                to: 100,
                color: '#f4177a',
                name: 'Hoch',
              },
              {
                from: 101,
                to: 200,
                color: '#c11361',
                name: 'Extrem',
              },
              {
                from: 201,
                to: 1000,
                color: '#770737',
                name: 'Höchste',
              }
            ]
          }
        }
      }
    }
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.heatmapTarget, options);
    if (chart) {
      chart.render();
    }
  }
}
