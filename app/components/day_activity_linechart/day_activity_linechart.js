import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['linechart'];
  static values = {
    url: String,
  };

  connect() {
    this.fetchLinechartData(this.urlValue);
  }

  async fetchLinechartData(endpoint) {
    const response = await fetch(endpoint);
    const jsonResponse = await response.json();
    const options = this.setupLinechart(jsonResponse);
    this.renderChart(options);
  }

  setupLinechart(jsonResponse) {
    const series = jsonResponse.map(response => {
      response.data = Object.entries(response.data).map(([key, value]) => ({
        x: key,
        y: value,
      }));
    });
    return {
      chart: {
        type: 'line',
      },
      series: jsonResponse,
      xaxis: {
        type: 'category',
      },
      stroke: {
        curve: 'smooth',
      },
      colors: ['#67D881', '#F4177A']
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.linechartTarget, options);
    if (chart) {
      chart.render();
    }
  }
}
