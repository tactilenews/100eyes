import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['heatmap', 'repliesButton', 'requestsButton'];
  static classes = ['active'];
  static values = {
    repliesChartUrl: String,
    requestsChartUrl: String,
  };

  connect() {
    this.renderRepliesHeatmap();
  }

  async fetchData(endpoint) {
    const response = await fetch(endpoint);
    return response.json();
  }

  async fetchHeatmapData(endpoint) {
    const response = await fetch(endpoint);
    const jsonResponse = await response.json();
    const options = this.setupHeatmap(jsonResponse);
    this.renderChart(options);
  }

  setupHeatmap(jsonResponse) {
    const series = [
      'Sonntag',
      'Samstag',
      'Freitag',
      'Donnerstag',
      'Mittwoch',
      'Dienstag',
      'Montag',
    ].map(day => ({ name: day, data: [] }));
    const maxValue = Math.max(...Object.values(jsonResponse));
    const maxValueDividedByColorSegments = maxValue / 6;
    Object.entries(jsonResponse).map(([key, value]) => {
      series.map(object => {
        if (JSON.parse(key)[0] == object.name) {
          object.data.push({ x: JSON.parse(key)[1], y: value });
        }
      });
    });
    const labelConfig = { labels: {
      style: {
          fontSize: '16px',
          fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
      },
    } }

    return {
      chart: {
        type: 'heatmap',
      },
      series: series,
      xaxis: labelConfig,
      yaxis: labelConfig,
      legend: {
        show: true,
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
      },
      plotOptions: {
        heatmap: {
          colorScale: {
            ranges: [
              {
                from: 0,
                to: maxValueDividedByColorSegments,
                color: '#F8C8DC',
                name: 'keine oder geringe',
              },
              {
                from: maxValueDividedByColorSegments + 1,
                to: 2 * maxValueDividedByColorSegments,
                color: '#FFB6C1',
                name: 'kaum',
              },
              {
                from: 2 * maxValueDividedByColorSegments + 1,
                to: 3 * maxValueDividedByColorSegments,
                color: '#FF00A0',
                name: 'mittlere',
              },
              {
                from: 3 * maxValueDividedByColorSegments + 1,
                to: 4 * maxValueDividedByColorSegments,
                color: '#F4177A',
                name: 'starke',
              },
              {
                from: 4 * maxValueDividedByColorSegments + 1,
                to: 5 * maxValueDividedByColorSegments,
                color: '#FF1493',
                name: 'Extrem',
              },
              {
                from: 5 * maxValueDividedByColorSegments + 1,
                to: 6 * maxValueDividedByColorSegments,
                color: '#C71585',
                name: 'stärkste [Aktivität]',
              },
            ],
          },
        },
      },
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.heatmapTarget, options);
    if (chart) {
      this.heatmapTarget.innerHTML = '';
      chart.render();
    }
  }

  renderRepliesHeatmap() {
    this.requestsButtonTarget.classList.remove(this.activeClass);
    this.repliesButtonTarget.classList.add(this.activeClass);
    this.fetchHeatmapData(this.repliesChartUrlValue);
  }

  renderRequestsHeatmap() {
    this.repliesButtonTarget.classList.remove(this.activeClass);
    this.requestsButtonTarget.classList.add(this.activeClass);
    this.fetchHeatmapData(this.requestsChartUrlValue);
  }
}
