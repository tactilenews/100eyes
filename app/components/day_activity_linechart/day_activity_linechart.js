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
    const labelConfig = { labels: {
      style: {
          fontSize: '16px',
          fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
      },
    } }
    return {
      chart: {
        type: 'line',
      },
      series: jsonResponse,
      xaxis: labelConfig,
      yaxis: labelConfig,
      stroke: {
        curve: 'smooth',
      },
      colors: ['#67D881', '#F4177A'],
      legend: {
        position: 'bottom',
        fontSize: '16px',
        fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
        markers: {
            width: 16,
            height: 16,
            radius: 16,
        },
        itemMargin: {
            horizontal: 10,
        },
      }
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.linechartTarget, options);
    if (chart) {
      chart.render();
    }
  }
}
