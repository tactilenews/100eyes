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
    const fontStyles = {
      style: {
        fontSize: '16px',
        fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
      },
    };

    return {
      chart: {
        type: 'line',
      },
      series: jsonResponse,
      xaxis: {
        labels: {
          ...fontStyles,
        },
      },
      yaxis: {
        labels: {
          ...fontStyles,
        },
        title: {
          ...fontStyles,
          text: 'Interaktionen',
        },
      },
      stroke: {
        curve: 'smooth',
      },
      colors: ['#0898FF', '#F4177A'],
      legend: {
        ...fontStyles.style,
        position: 'bottom',
        markers: {
          width: 16,
          height: 16,
          radius: 16,
        },
        itemMargin: {
          horizontal: 10,
        },
      },
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.linechartTarget, options);
    if (chart) {
      chart.render();
    }
  }
}
