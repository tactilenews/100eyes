import { Controller } from "@hotwired/stimulus";
import Rails from '@rails/ujs';

export default class extends Controller {
  static targets = ['heatmap'];

  connect() {
    this.fetchTimeBasedActivityData();
    console.log('connected', this.heatmapTarget);
  }

  async fetchTimeBasedActivityData() {
    const response = await fetch('charts/time-based-activity');
    const jsonResponse = await response.json();
    const options = this.setUpChart(jsonResponse)
    this.renderChart(options)
  }

  setUpChart(jsonResponse) {
    var dataArray = [];
    for (const [key, value] of Object.entries(jsonResponse)) {
      dataArray.push({ x: key, y: value })
    }

    const series = ["Sonntag", "Montag", "Dientsag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"].map(day => {
      return {
        name: day,
        data: dataArray,
      }
    })
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
                color: '#00A100',
                name: 'low',
              },
              {
                from: 6,
                to: 20,
                color: '#128FD9',
                name: 'medium',
              },
              {
                from: 21,
                to: 45,
                color: '#FFB200',
                name: 'high',
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
